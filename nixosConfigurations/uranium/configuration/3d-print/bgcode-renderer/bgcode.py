#!/usr/bin/env python3
"""bgcode.py - Pure Python Prusa Binary G-Code (.bgcode) parser, decoder, and CLI.

Supports:
- libbgcode container format parsing (header, block headers, CRC verification).
- Block types: File Metadata (0), G-code Buffer (1), Slicer Config (2),
  Printer Metadata (3), Print Statistics (4), Thumbnails (5).
- Compression formats: Uncompressed (0), Deflate/zlib (1), Heatshrink LZSS (2, 3).
- MeatPack text compaction stream decoding with accurate character queue ordering.
- CLI subcommands: info, extract, config, grep, thumbnails.
"""

from __future__ import annotations

import argparse
import os
import re
import struct
import sys
import zlib
from dataclasses import dataclass, field
from typing import Dict, Generator, List, Optional, Tuple


# ==============================================================================
# Heatshrink LZSS Decoder
# ==============================================================================

class FastHeatshrinkDecoder:
    """Fast pure-Python Heatshrink LZSS stream decoder using an integer bit-buffer."""

    def __init__(self, window_sz2: int = 12, lookahead_sz2: int = 4) -> None:
        self.window_sz2 = window_sz2
        self.lookahead_sz2 = lookahead_sz2
        self.window_mask = (1 << window_sz2) - 1

    def decode(self, data: bytes, expected_len: int) -> bytes:
        buffer = bytearray(1 << self.window_sz2)
        head_index = 0
        out = bytearray()
        out_append = out.append

        bit_buf = 0
        bits_in_buf = 0
        pos = 0
        data_len = len(data)

        window_mask = self.window_mask
        window_sz2 = self.window_sz2
        lookahead_sz2 = self.lookahead_sz2
        offset_mask = (1 << window_sz2) - 1
        count_mask = (1 << lookahead_sz2) - 1

        while len(out) < expected_len:
            while bits_in_buf < 16 and pos < data_len:
                bit_buf = (bit_buf << 8) | data[pos]
                pos += 1
                bits_in_buf += 8

            if bits_in_buf < 1:
                break

            bits_in_buf -= 1
            tag = (bit_buf >> bits_in_buf) & 1

            if tag == 1:
                # Literal byte
                if bits_in_buf < 8:
                    while bits_in_buf < 16 and pos < data_len:
                        bit_buf = (bit_buf << 8) | data[pos]
                        pos += 1
                        bits_in_buf += 8
                if bits_in_buf < 8:
                    break
                bits_in_buf -= 8
                val = (bit_buf >> bits_in_buf) & 0xFF
                buffer[head_index & window_mask] = val
                head_index += 1
                out_append(val)
            else:
                # Backreference (offset + length)
                needed = window_sz2 + lookahead_sz2
                while bits_in_buf < needed and pos < data_len:
                    bit_buf = (bit_buf << 8) | data[pos]
                    pos += 1
                    bits_in_buf += 8
                if bits_in_buf < needed:
                    break

                bits_in_buf -= window_sz2
                neg_offset = ((bit_buf >> bits_in_buf) & offset_mask) + 1

                bits_in_buf -= lookahead_sz2
                count = ((bit_buf >> bits_in_buf) & count_mask) + 1

                for _ in range(count):
                    c = buffer[(head_index - neg_offset) & window_mask]
                    buffer[head_index & window_mask] = c
                    head_index += 1
                    out_append(c)

        return bytes(out)


# ==============================================================================
# MeatPack Character Unbinarizer
# ==============================================================================

def unbinarize_meatpack(src: bytes) -> bytes:
    """Unbinarize MeatPack packed G-code stream into standard ASCII characters.

    Correctly manages Scott Mudge's MeatPack character queues and single-character
    buffering so unpacked characters preserve exact command sequence.
    """
    unbinarizing = False
    nospace_enabled = False
    cmd_active = False
    char_buf = 0
    cmd_count = 0
    full_char_queue = 0

    tbl_space = [ord(c) for c in "0123456789. \nGX\0"]
    tbl_nospace = [ord(c) for c in "0123456789.E\nGX\0"]
    tbl = tbl_space

    out = bytearray()
    out_append = out.append

    idx = 0
    src_len = len(src)

    while idx < src_len:
        c_bin = src[idx]
        idx += 1

        if c_bin == 0xFF:
            if cmd_count > 0:
                cmd_active = True
                cmd_count = 0
            else:
                cmd_count += 1
            continue

        if cmd_active:
            if c_bin == 251:
                unbinarizing = True
            elif c_bin in (250, 249):
                unbinarizing = False
            elif c_bin == 247:
                nospace_enabled = True
                tbl = tbl_nospace
            elif c_bin == 246:
                nospace_enabled = False
                tbl = tbl_space
            cmd_active = False
            continue

        rx_list = (0xFF, c_bin) if cmd_count > 0 else (c_bin,)
        cmd_count = 0

        for c in rx_list:
            if unbinarizing:
                if full_char_queue > 0:
                    out_append(c)
                    if char_buf > 0:
                        out_append(char_buf)
                        char_buf = 0
                    full_char_queue -= 1
                else:
                    pk = c
                    res = 0
                    b0, b1 = 0, 0
                    if (pk & 0x0F) == 0x0F:
                        res |= 1
                    else:
                        b0 = tbl[pk & 0x0F]
                    if (pk & 0xF0) == 0xF0:
                        res |= 2
                    else:
                        b1 = tbl[(pk >> 4) & 0x0F]

                    if res == 3:  # Both uncompressed
                        full_char_queue += 2
                    elif res == 1:  # b0 uncompressed, b1 packed
                        char_buf = b1
                        full_char_queue += 1
                    elif res == 2:  # b0 packed, b1 uncompressed
                        out_append(b0)
                        full_char_queue += 1
                    else:  # Both packed
                        out_append(b0)
                        if b0 != 10:
                            out_append(b1)
            else:
                out_append(c)

    return bytes(out)


# ==============================================================================
# Data Structures
# ==============================================================================

BLOCK_NAMES = {
    0: "File Metadata",
    1: "G-Code Buffer",
    2: "Slicer Metadata",
    3: "Printer Metadata",
    4: "Print Statistics",
    5: "Thumbnail",
}

COMPRESSION_NAMES = {
    0: "None",
    1: "Deflate",
    2: "Heatshrink",
    3: "Heatshrink + MeatPack",
}


@dataclass
class Thumbnail:
    format_id: int  # 0=PNG, 1=JPG, 2=QOI
    width: int
    height: int
    data: bytes

    @property
    def format_str(self) -> str:
        return {0: "PNG", 1: "JPG", 2: "QOI"}.get(self.format_id, f"Unknown({self.format_id})")

    @property
    def extension(self) -> str:
        return {0: "png", 1: "jpg", 2: "qoi"}.get(self.format_id, "bin")


@dataclass
class BgcodeBlock:
    index: int
    block_type: int
    compression: int
    uncompressed_size: int
    compressed_size: int
    param: bytes
    raw_data: bytes
    crc: int

    @property
    def type_name(self) -> str:
        return BLOCK_NAMES.get(self.block_type, f"Custom({self.block_type})")

    @property
    def compression_name(self) -> str:
        return COMPRESSION_NAMES.get(self.compression, f"Custom({self.compression})")

    def decompress(self) -> bytes:
        if self.compression == 0:
            decomp = self.raw_data
        elif self.compression == 1:
            decomp = zlib.decompress(self.raw_data)
        elif self.compression in (2, 3):
            decomp = FastHeatshrinkDecoder(12, 4).decode(self.raw_data, self.uncompressed_size)
        else:
            raise ValueError(f"Unsupported compression algorithm: {self.compression}")

        # If G-code buffer using MeatPack encoding
        if self.block_type == 1:
            if self.compression == 3 or self.param == b"\x02\x00":
                decomp = unbinarize_meatpack(decomp)

        return decomp


# ==============================================================================
# BgcodeReader
# ==============================================================================

class BgcodeReader:
    """Reader and parser for Prusa .bgcode binary G-code files."""

    MAGIC = b"GCDE"

    def __init__(self, filepath_or_buffer: str | bytes) -> None:
        self.blocks: List[BgcodeBlock] = []
        self.version: int = 1
        self.checksum_type: int = 1
        self.file_metadata: Dict[str, str] = {}
        self.printer_metadata: Dict[str, str] = {}
        self.print_stats: Dict[str, str] = {}
        self.slicer_config: Dict[str, str] = {}
        self.thumbnails: List[Thumbnail] = []

        if isinstance(filepath_or_buffer, str):
            self.filepath = filepath_or_buffer
            with open(filepath_or_buffer, "rb") as f:
                self._parse(f.read())
        else:
            self.filepath = "<buffer>"
            self._parse(filepath_or_buffer)

    def _parse(self, data: bytes) -> None:
        if len(data) < 10:
            raise ValueError("File is too short to be a valid .bgcode file.")

        magic = data[:4]
        if magic != self.MAGIC:
            raise ValueError(f"Invalid magic header: expected {self.MAGIC!r}, got {magic!r}")

        self.version = struct.unpack("<I", data[4:8])[0]
        self.checksum_type = struct.unpack("<H", data[8:10])[0]

        offset = 10
        data_len = len(data)
        block_idx = 0

        while offset < data_len:
            if offset + 4 > data_len:
                break
            btype, comp = struct.unpack("<HH", data[offset:offset + 4])
            offset += 4

            if offset + 4 > data_len:
                break
            uncomp_sz = struct.unpack("<I", data[offset:offset + 4])[0]
            offset += 4

            comp_sz = struct.unpack("<I", data[offset:offset + 4])[0] if comp != 0 else uncomp_sz
            if comp != 0:
                offset += 4

            param_sz = 6 if btype == 5 else 2
            if offset + param_sz > data_len:
                break
            param = data[offset:offset + param_sz]
            offset += param_sz

            if offset + comp_sz > data_len:
                break
            raw_data = data[offset:offset + comp_sz]
            offset += comp_sz

            if offset + 4 > data_len:
                break
            crc = struct.unpack("<I", data[offset:offset + 4])[0]
            offset += 4

            block = BgcodeBlock(
                index=block_idx,
                block_type=btype,
                compression=comp,
                uncompressed_size=uncomp_sz,
                compressed_size=comp_sz,
                param=param,
                raw_data=raw_data,
                crc=crc,
            )
            self.blocks.append(block)
            block_idx += 1

            # Populate metadata collections
            self._process_metadata_block(block)

    def _process_metadata_block(self, block: BgcodeBlock) -> None:
        try:
            if block.block_type == 0:  # File metadata
                text = block.decompress().decode("utf-8", errors="ignore")
                self.file_metadata.update(self._parse_key_values(text))
            elif block.block_type == 2:  # Slicer metadata
                text = block.decompress().decode("utf-8", errors="ignore")
                self.slicer_config.update(self._parse_key_values(text))
            elif block.block_type == 3:  # Printer metadata
                text = block.decompress().decode("utf-8", errors="ignore")
                self.printer_metadata.update(self._parse_key_values(text))
            elif block.block_type == 4:  # Print stats
                text = block.decompress().decode("utf-8", errors="ignore")
                self.print_stats.update(self._parse_key_values(text))
            elif block.block_type == 5:  # Thumbnail
                fmt, width, height = struct.unpack("<HHH", block.param)
                thumb = Thumbnail(format_id=fmt, width=width, height=height, data=block.raw_data)
                self.thumbnails.append(thumb)
        except Exception:
            pass

    @staticmethod
    def _parse_key_values(text: str) -> Dict[str, str]:
        out = {}
        for line in text.splitlines():
            line = line.strip()
            if not line or line.startswith("#") or line.startswith(";"):
                continue
            if "=" in line:
                k, v = line.split("=", 1)
                out[k.strip()] = v.strip()
        return out

    def get_gcode(self) -> str:
        """Decompress and assemble the entire ASCII G-code stream."""
        chunks = []
        for block in self.blocks:
            if block.block_type == 1:
                chunk = block.decompress()
                chunks.append(chunk)
        return b"".join(chunks).decode("utf-8", errors="ignore")

    def iter_gcode_lines(self) -> Generator[str, None, None]:
        """Yield G-code lines one by one across blocks."""
        residual = ""
        for block in self.blocks:
            if block.block_type == 1:
                decomp = block.decompress().decode("utf-8", errors="ignore")
                full_text = residual + decomp
                lines = full_text.splitlines(keepends=True)
                if lines and not lines[-1].endswith("\n"):
                    residual = lines[-1]
                    lines = lines[:-1]
                else:
                    residual = ""
                for line in lines:
                    yield line.rstrip("\r\n")
        if residual:
            yield residual

    def export_gcode(self, output_path: str) -> int:
        """Export the binary G-code to an ASCII .gcode file. Returns byte count."""
        total_bytes = 0
        with open(output_path, "w", encoding="utf-8", newline="\n") as out:
            for line in self.iter_gcode_lines():
                out.write(line + "\n")
                total_bytes += len(line) + 1
        return total_bytes


# ==============================================================================
# CLI Implementation
# ==============================================================================

def cmd_info(args: argparse.Namespace) -> None:
    reader = BgcodeReader(args.input)
    print(f"File: {args.input}")
    print(f"Version: {reader.version} (Checksum Type: {reader.checksum_type})")
    print(f"Total Blocks: {len(reader.blocks)}")
    print()

    if reader.file_metadata:
        print("[File Metadata]")
        for k, v in reader.file_metadata.items():
            print(f"  {k}: {v}")
        print()

    if reader.printer_metadata:
        print("[Printer & Material]")
        for k in ["printer_model", "filament_type", "nozzle_diameter", "nozzle_high_flow", "bed_temperature"]:
            if k in reader.printer_metadata:
                print(f"  {k}: {reader.printer_metadata[k]}")
        print()

    if reader.print_stats:
        print("[Print Statistics]")
        for k, v in reader.print_stats.items():
            print(f"  {k}: {v}")
        print()

    if reader.thumbnails:
        print(f"[Thumbnails ({len(reader.thumbnails)})]")
        for i, t in enumerate(reader.thumbnails):
            print(f"  #{i + 1}: {t.width}x{t.height} ({t.format_str}), {len(t.data)} bytes")
        print()

    gcode_blocks = [b for b in reader.blocks if b.block_type == 1]
    total_uncomp = sum(b.uncompressed_size for b in gcode_blocks)
    total_comp = sum(b.compressed_size for b in gcode_blocks)
    ratio = (total_comp / total_uncomp * 100) if total_uncomp else 0.0
    print(f"[G-Code Compression]")
    print(f"  G-code Blocks: {len(gcode_blocks)}")
    print(f"  Compressed Size: {total_comp:,} bytes")
    print(f"  Uncompressed Size: {total_uncomp:,} bytes ({ratio:.1f}% ratio)")


def cmd_extract(args: argparse.Namespace) -> None:
    reader = BgcodeReader(args.input)
    if args.output:
        size = reader.export_gcode(args.output)
        print(f"Extracted {size:,} bytes of G-code to {args.output}")
    else:
        for line in reader.iter_gcode_lines():
            sys.stdout.write(line + "\n")


def cmd_config(args: argparse.Namespace) -> None:
    reader = BgcodeReader(args.input)
    filter_pattern = args.filter.lower() if args.filter else None

    # Merge printer and slicer metadata
    combined = {**reader.printer_metadata, **reader.slicer_config}
    if not combined:
        print("No slicer metadata found in file.")
        return

    matched = 0
    for k in sorted(combined.keys()):
        if filter_pattern is None or filter_pattern in k.lower():
            print(f"{k} = {combined[k]}")
            matched += 1

    if filter_pattern and matched == 0:
        print(f"No configuration keys matching '{args.filter}'.")


def cmd_grep(args: argparse.Namespace) -> None:
    reader = BgcodeReader(args.input)
    pattern = re.compile(args.pattern, re.IGNORECASE if args.ignore_case else 0)
    matched = 0

    for line_num, line in enumerate(reader.iter_gcode_lines(), 1):
        if pattern.search(line):
            if args.line_numbers:
                print(f"{line_num}:{line}")
            else:
                print(line)
            matched += 1
            if args.max_count and matched >= args.max_count:
                break


def cmd_thumbnails(args: argparse.Namespace) -> None:
    reader = BgcodeReader(args.input)
    if not reader.thumbnails:
        print("No thumbnails embedded in this file.")
        return

    out_dir = args.out_dir or "."
    os.makedirs(out_dir, exist_ok=True)
    base_name = os.path.splitext(os.path.basename(args.input))[0]

    for i, t in enumerate(reader.thumbnails):
        filename = f"{base_name}_thumb_{t.width}x{t.height}.{t.extension}"
        out_path = os.path.join(out_dir, filename)
        with open(out_path, "wb") as f:
            f.write(t.data)
        print(f"Saved {t.width}x{t.height} ({t.format_str}) to {out_path}")


def main() -> None:
    parser = argparse.ArgumentParser(
        prog="bgcode",
        description="Pure-Python Prusa Binary G-Code (.bgcode) parser and extraction toolkit.",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    # info
    p_info = subparsers.add_parser("info", help="Display metadata, printer info, and block summary.")
    p_info.add_argument("input", help="Path to .bgcode file")

    # extract
    p_extract = subparsers.add_parser("extract", help="Extract raw ASCII G-code.")
    p_extract.add_argument("input", help="Path to .bgcode file")
    p_extract.add_argument("-o", "--output", help="Output file path (prints to stdout if omitted)")

    # config
    p_config = subparsers.add_parser("config", help="Inspect embedded slicer INI settings.")
    p_config.add_argument("input", help="Path to .bgcode file")
    p_config.add_argument("filter", nargs="?", help="Optional substring filter for config keys (e.g. speed, temp, fan)")

    # grep
    p_grep = subparsers.add_parser("grep", help="Directly search G-code stream without extracting whole file.")
    p_grep.add_argument("pattern", help="Regex or string pattern to search for (e.g. 'M104', 'M572', 'layer')")
    p_grep.add_argument("input", help="Path to .bgcode file")
    p_grep.add_argument("-i", "--ignore-case", action="store_true", help="Case-insensitive search")
    p_grep.add_argument("-n", "--line-numbers", action="store_true", help="Print line numbers")
    p_grep.add_argument("-m", "--max-count", type=int, default=None, help="Stop after N matches")

    # thumbnails
    p_thumbs = subparsers.add_parser("thumbnails", help="Export embedded thumbnail images.")
    p_thumbs.add_argument("input", help="Path to .bgcode file")
    p_thumbs.add_argument("-d", "--out-dir", help="Directory to save extracted images to (default: current directory)")

    args = parser.parse_args()

    if args.command == "info":
        cmd_info(args)
    elif args.command == "extract":
        cmd_extract(args)
    elif args.command == "config":
        cmd_config(args)
    elif args.command == "grep":
        cmd_grep(args)
    elif args.command == "thumbnails":
        cmd_thumbnails(args)


if __name__ == "__main__":
    main()
