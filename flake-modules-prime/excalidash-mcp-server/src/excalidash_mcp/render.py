"""Render a drawing (including embedded images) to a PNG, purely from data
already reachable through the REST API — no browser, no login session.

Earlier approach (kept here in history, not code) was a headless-Chromium
screenshot of the real editor, to work around exportToSvg's browser-only
nature and its known image-flattening bug. That needed a real login
session, which this deployment's OIDC-only auth makes impractical to
automate. Building our own compositor (./compositor.py) sidesteps needing a
browser or session at all: it's pure Python over get_drawing's elements and
get_file's image bytes, then rasterized with `resvg` (a small, dependency-
light Rust SVG renderer — no Chromium, no fonts-in-a-browser-profile setup).

Trade-off: flat shapes, not Excalidraw's hand-drawn "rough" look — see
compositor.py's module docstring.
"""

from __future__ import annotations

import os
import shutil
import subprocess
from typing import Any

from . import graph
from .client import ExcalidashClient
from .compositor import build_svg


class RenderError(RuntimeError):
    pass


def _resvg_path() -> str:
    found = shutil.which("resvg")
    if not found:
        raise RenderError("resvg not found on PATH")
    return found


def _font_args() -> list[str]:
    # Set by the Nix package (--set-default) to a bundled Liberation Sans,
    # so text renders without depending on the host's fontconfig/font
    # packages being set up at all. compositor.py always emits
    # font-family="sans-serif", which --sans-serif-family remaps here.
    fonts_dir = os.environ.get("EXCALIDASH_RENDER_FONTS_DIR")
    if not fonts_dir:
        return []
    return [
        "--use-fonts-dir",
        fonts_dir,
        "--skip-system-fonts",
        "--sans-serif-family",
        "Liberation Sans",
    ]


Rect = tuple[float, float, float, float]


def _intersects(el: dict[str, Any], crop: Rect) -> bool:
    cx, cy, cw, ch = crop
    ex, ey = el.get("x", 0), el.get("y", 0)
    ew, eh = el.get("width", 0), el.get("height", 0)
    return not (ex + ew < cx or ex > cx + cw or ey + eh < cy or ey > cy + ch)


def _fetch_elements(client: ExcalidashClient, drawing_id: str) -> tuple[list[dict[str, Any]], str]:
    # include_assets=False (the default): only `elements`/`appState` are
    # needed here, never the `files` map itself — image bytes are always
    # fetched per-file via get_file below, filtered by `crop` when given.
    drawing = client.get_drawing(drawing_id)
    elements = drawing["elements"]
    background = (drawing.get("appState") or {}).get("viewBackgroundColor") or "#ffffff"
    return elements, background


def _fetch_images(
    client: ExcalidashClient,
    drawing_id: str,
    elements: list[dict[str, Any]],
    crop: Rect | None = None,
) -> dict[str, tuple[bytes, str]]:
    """Downloads each distinct image element's bytes, skipping ones that fall
    entirely outside `crop` (when given) — a full drawing can carry many
    megabytes of embedded photos, most of which are irrelevant to a single
    region/frame render and would otherwise be downloaded and discarded.
    """
    images: dict[str, tuple[bytes, str]] = {}
    for element in elements:
        file_id = element.get("fileId")
        if element.get("type") != "image" or not file_id or file_id in images:
            continue
        if crop is not None and not _intersects(element, crop):
            continue
        try:
            images[file_id] = client.get_file(drawing_id, file_id)
        except Exception:
            pass  # missing/unreachable image: compositor falls back to a placeholder box
    return images


def _rasterize(svg: str) -> bytes:
    try:
        result = subprocess.run(
            [_resvg_path(), "-", "-c"] + _font_args(),
            input=svg.encode(),
            capture_output=True,
            timeout=30,
        )
    except subprocess.TimeoutExpired as exc:
        raise RenderError("resvg timed out") from exc
    if result.returncode != 0:
        raise RenderError(f"resvg failed: {result.stderr.decode(errors='replace')}")
    return result.stdout


def render_drawing_preview(client: ExcalidashClient, drawing_id: str) -> bytes:
    elements, background = _fetch_elements(client, drawing_id)
    images = _fetch_images(client, drawing_id, elements)
    svg = build_svg(elements, images, background_color=background)
    return _rasterize(svg)


def render_drawing_region(
    client: ExcalidashClient,
    drawing_id: str,
    x: float,
    y: float,
    width: float,
    height: float,
) -> bytes:
    """Same as render_drawing_preview, but rasterizes only the given (x, y,
    width, height) rectangle in element coordinates instead of auto-fitting
    the whole scene — for zooming into one region of a large diagram.
    """
    elements, background = _fetch_elements(client, drawing_id)
    crop = (x, y, width, height)
    images = _fetch_images(client, drawing_id, elements, crop=crop)
    svg = build_svg(elements, images, background_color=background, crop=crop)
    return _rasterize(svg)


def render_frame(client: ExcalidashClient, drawing_id: str, frame_ref: str) -> bytes:
    """Renders just one frame's bounds, resolved by id or name (see
    graph.find_frame) — the single-call equivalent of extract_frame's
    bounds fed into render_drawing_region.
    """
    elements, background = _fetch_elements(client, drawing_id)
    frame = graph.find_frame(elements, frame_ref)
    crop = (frame["x"], frame["y"], frame.get("width", 0), frame.get("height", 0))
    images = _fetch_images(client, drawing_id, elements, crop=crop)
    svg = build_svg(elements, images, background_color=background, crop=crop)
    return _rasterize(svg)
