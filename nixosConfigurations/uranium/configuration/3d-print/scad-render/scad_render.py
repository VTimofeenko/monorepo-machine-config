#!/usr/bin/env python3
"""scad-render - render OpenSCAD models (or meshes) to PNG for quick review.

Thin layer over `openscad`: fills in defaults, accepts a few shorthands and
passes everything else through untouched.
"""

from __future__ import annotations

import os
import subprocess
import sys
import tempfile

USAGE = """\
Usage: scad-render [options] INPUT [-o OUTPUT]

INPUT is a .scad file, or a mesh (.stl/.3mf/.obj/.off/.amf) to import.

  -o, --output FILE      Output file (default: INPUT with .png extension).
                         Non-PNG outputs (.stl, .3mf, ...) export as usual.
  --camera ELEV,AZIM     View from ELEV degrees above the horizon (90 = top
                         down), rotated AZIM degrees around Z. Model is
                         auto-framed. OpenSCAD's 6/7-number forms also work.
  --colorscheme NAME     Default: Tomorrow. Unknown names fall back to it.
  --imgsize W,H          Default: 1024,1024.
  --preview              Fast OpenCSG preview instead of the full render.
                         Full render (default) shows exactly what gets exported
                         and fails on geometry errors.
  -D var=val             Override a variable in the model.

Any other option is passed to openscad unchanged (see `openscad --help`).
"""

COLORSCHEMES = {
    "Cornfield", "Metallic", "Sunset", "Starnight", "BeforeDawn", "Nature",
    "Daylight Gem", "Nocturnal Gem", "DeepOcean", "Solarized", "Tomorrow",
    "Tomorrow Night", "ClearSky", "Monotone",
}
DEFAULT_COLORSCHEME = "Tomorrow"
DEFAULT_IMGSIZE = "1024,1024"
MESH_EXTS = {".stl", ".3mf", ".obj", ".off", ".amf"}
INPUT_EXTS = MESH_EXTS | {".scad"}
# openscad options that take a separate value argument
VALUE_OPTS = {"-D", "-p", "-P", "-d", "-m", "--export-format", "--backend",
              "--projection", "--csglimit", "--summary", "--summary-file",
              "--animate", "--view", "--enable"}


def warn(msg: str) -> None:
    print(f"scad-render: {msg}", file=sys.stderr)


def split_opt(args: list[str], i: int) -> tuple[str, str | None, int]:
    """Return (name, value, next_index) for a --name=value or --name value option."""
    a = args[i]
    if "=" in a:
        name, value = a.split("=", 1)
        return name, value, i + 1
    if i + 1 < len(args):
        return a, args[i + 1], i + 2
    return a, None, i + 1


def camera_arg(value: str) -> list[str]:
    parts = value.split(",")
    if len(parts) != 2:
        return [f"--camera={value}"]
    elev, azim = (float(p) for p in parts)
    # OpenSCAD gimbal: rot_x=0 looks straight down, 90 looks horizontally.
    gimbal = f"0,0,0,{90 - elev:g},0,{azim:g},500"
    return [f"--camera={gimbal}", "--viewall", "--autocenter"]


def build_command(args: list[str], mesh_scad: str | None = None) -> tuple[list[str], str | None]:
    """Translate scad-render args into an openscad argv.

    Returns (argv, mesh_input) where mesh_input is a mesh file that the caller
    must wrap into `mesh_scad` (a .scad path) via import(); argv already
    references `mesh_scad` in that case.
    """
    out: str | None = None
    inp: str | None = None
    colorscheme = DEFAULT_COLORSCHEME
    imgsize = DEFAULT_IMGSIZE
    modes: list[str] = []
    passthrough: list[str] = []

    i = 0
    while i < len(args):
        a = args[i]
        name = a.split("=", 1)[0]
        if name in ("-o", "--output"):
            _, out, i = split_opt(args, i)
        elif name == "--camera":
            _, value, i = split_opt(args, i)
            passthrough += camera_arg(value or "")
        elif name == "--colorscheme":
            _, value, i = split_opt(args, i)
            if value in COLORSCHEMES:
                colorscheme = value
            else:
                warn(f"unknown colorscheme {value!r}, using {DEFAULT_COLORSCHEME}. "
                     f"Valid: {', '.join(sorted(COLORSCHEMES))}")
        elif name == "--imgsize":
            _, imgsize, i = split_opt(args, i)
        elif name in ("--preview", "--render"):
            modes.append(a)
            i += 1
        elif a.startswith("-o") and len(a) > 2:
            out = a[2:]
            i += 1
        elif a in VALUE_OPTS and i + 1 < len(args):
            passthrough += [a, args[i + 1]]
            i += 2
        elif not a.startswith("-") and os.path.splitext(a)[1].lower() in INPUT_EXTS:
            inp = a
            i += 1
        else:
            passthrough.append(a)
            i += 1

    if inp is None:
        raise SystemExit(f"scad-render: no input file given\n\n{USAGE}")
    if out is None:
        out = os.path.splitext(inp)[0] + ".png"

    mesh_input = None
    if os.path.splitext(inp)[1].lower() in MESH_EXTS:
        mesh_input, inp = inp, mesh_scad or inp

    is_png = os.path.splitext(out)[1].lower() == ".png"
    if is_png and not modes:
        modes = ["--render"]
    # --render/--preview take an optional value and would swallow a following
    # input file, so they must be followed by another option (-o).
    argv = ["openscad", *modes, "-o", out]
    if is_png:
        argv += [f"--colorscheme={colorscheme}", f"--imgsize={imgsize}"]
    return argv + passthrough + [inp], mesh_input


def main() -> int:
    args = sys.argv[1:]
    if not args or "-h" in args or "--help" in args:
        print(USAGE)
        return 0

    with tempfile.TemporaryDirectory() as tmp:
        mesh_scad = os.path.join(tmp, "mesh.scad")
        argv, mesh_input = build_command(args, mesh_scad)
        if mesh_input is not None:
            if not os.path.isfile(mesh_input):
                warn(f"no such file: {mesh_input}")
                return 1
            with open(mesh_scad, "w") as f:
                f.write(f'import("{os.path.abspath(mesh_input)}");\n')
        # Run (not exec) so the temp dir outlives openscad.
        rc = subprocess.run(argv).returncode
        if rc == 0:
            print(f"scad-render: wrote {argv[argv.index('-o') + 1]}", file=sys.stderr)
        return rc


if __name__ == "__main__":
    sys.exit(main())
