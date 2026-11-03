#!/usr/bin/env python3
"""test_bgcode.py - Verification tests for bgcode.py using a single reference file."""

import os
import tempfile
import unittest

from bgcode import BgcodeReader, Thumbnail


def find_test_file() -> str:
    """Locate the reference test file across various execution directories."""
    candidates = [
        os.environ.get("BGCODE_TEST_FILE", ""),
        os.path.join(os.path.dirname(os.path.abspath(__file__)), "./shape.bgcode"),
    ]
    for c in candidates:
        if c and os.path.isfile(c):
            return os.path.abspath(c)
    raise FileNotFoundError("Could not locate reference test file")


class TestBgcodeParser(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.test_file = find_test_file()
        cls.reader = BgcodeReader(cls.test_file)

    def test_container_and_blocks(self) -> None:
        self.assertEqual(self.reader.version, 1)
        self.assertEqual(self.reader.checksum_type, 1)
        self.assertEqual(len(self.reader.blocks), 10)

        # Verify block type breakdown in Shape-Box file
        block_types = [b.block_type for b in self.reader.blocks]
        self.assertIn(0, block_types)  # File metadata
        self.assertIn(1, block_types)  # G-code buffers
        self.assertIn(2, block_types)  # Slicer config
        self.assertIn(3, block_types)  # Printer metadata
        self.assertIn(4, block_types)  # Print stats
        self.assertIn(5, block_types)  # Thumbnails

    def test_file_metadata(self) -> None:
        self.assertIn("Producer", self.reader.file_metadata)
        self.assertIn("PrusaSlicer", self.reader.file_metadata["Producer"])
        self.assertIn("Produced on", self.reader.file_metadata)

    def test_printer_metadata(self) -> None:
        self.assertEqual(self.reader.printer_metadata.get("printer_model"), "COREONE")
        self.assertEqual(self.reader.printer_metadata.get("filament_type"), "PETG")
        self.assertEqual(self.reader.printer_metadata.get("nozzle_diameter"), "0.4")
        self.assertEqual(self.reader.printer_metadata.get("nozzle_high_flow"), "0")

    def test_slicer_config(self) -> None:
        self.assertEqual(self.reader.slicer_config.get("external_perimeter_speed"), "170")
        self.assertEqual(self.reader.slicer_config.get("perimeter_speed"), "150")
        self.assertEqual(self.reader.slicer_config.get("first_layer_temperature"), "255")

    def test_print_statistics(self) -> None:
        self.assertIn("filament used [mm]", self.reader.print_stats)
        self.assertEqual(self.reader.print_stats.get("filament used [mm]"), "605.64")
        self.assertIn("estimated printing time (normal mode)", self.reader.print_stats)

    def test_thumbnail_extraction(self) -> None:
        self.assertEqual(len(self.reader.thumbnails), 4)
        dims = [(t.width, t.height, t.format_str) for t in self.reader.thumbnails]
        expected_dims = [
            (16, 16, "QOI"),
            (313, 173, "QOI"),
            (480, 240, "QOI"),
            (380, 285, "PNG"),
        ]
        self.assertEqual(dims, expected_dims)
        for t in self.reader.thumbnails:
            self.assertTrue(len(t.data) > 0)

    def test_gcode_stream_and_decompression(self) -> None:
        lines = list(self.reader.iter_gcode_lines())
        self.assertGreater(len(lines), 4000)

        full_gcode = "\n".join(lines)
        self.assertIn("M73 P0", full_gcode)
        self.assertIn("M140 S85", full_gcode)
        self.assertIn("M104 S255", full_gcode)
        self.assertIn("M572 S0.053", full_gcode)
        self.assertIn("M84", full_gcode)
        self.assertTrue("G1X" in full_gcode or "G1 X" in full_gcode)

    def test_export_gcode_file(self) -> None:
        with tempfile.NamedTemporaryFile(suffix=".gcode", delete=False) as tmp:
            tmp_path = tmp.name

        try:
            bytes_written = self.reader.export_gcode(tmp_path)
            self.assertGreater(bytes_written, 50000)
            self.assertTrue(os.path.isfile(tmp_path))
            with open(tmp_path, "r", encoding="utf-8") as f:
                content = f.read()
            self.assertIn("M140 S85", content)
            self.assertIn("M572 S0.053", content)
        finally:
            if os.path.exists(tmp_path):
                os.remove(tmp_path)


if __name__ == "__main__":
    unittest.main()
