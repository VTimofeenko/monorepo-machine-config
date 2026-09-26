"""Renders an Excalidraw element list (plus embedded image bytes) to a flat
SVG — a from-scratch compositor, not a reimplementation of Excalidraw's own
`exportToSvg`/rough.js sketchy-stroke rendering.

Why this exists instead of calling Excalidraw's own export: that function
only runs in a browser (see render_drawing_preview's earlier history — a
headless Chromium + real login was the only way to invoke it, since its
published bundle isn't loadable under plain Node ESM either). This module
needs neither a browser nor a login: it's pure Python over the same
elements/files JSON get_drawing/get_file already fetch through the REST API.

Trade-off: plain flat shapes, not Excalidraw's hand-drawn/"rough" look, and
no fancy fill patterns (hachure/cross-hatch collapse to solid). Good enough
to verify layout and see an embedded image in place — not a substitute for
opening the real editor if the sketchy styling itself matters.
"""

from __future__ import annotations

import base64
import math
from typing import Any
from xml.sax.saxutils import escape

PADDING = 20


def _num(value: Any, default: float = 0.0) -> float:
    return value if isinstance(value, (int, float)) else default


def _bbox(elements: list[dict[str, Any]]) -> tuple[float, float, float, float]:
    xs, ys = [], []
    for el in elements:
        if el.get("isDeleted"):
            continue
        x, y = _num(el.get("x")), _num(el.get("y"))
        w, h = _num(el.get("width")), _num(el.get("height"))
        xs.extend([x, x + w])
        ys.extend([y, y + h])
    if not xs:
        return (0, 0, 100, 100)
    return (min(xs), min(ys), max(xs), max(ys))


def _rotation(el: dict[str, Any]) -> str:
    angle = _num(el.get("angle"))
    if not angle:
        return ""
    cx = el["x"] + el.get("width", 0) / 2
    cy = el["y"] + el.get("height", 0) / 2
    return f' transform="rotate({math.degrees(angle):.2f} {cx:.2f} {cy:.2f})"'


def _fill(el: dict[str, Any]) -> str:
    bg = el.get("backgroundColor") or "transparent"
    return "none" if bg == "transparent" else bg


def _stroke_attrs(el: dict[str, Any]) -> str:
    stroke = el.get("strokeColor") or "#1e1e1e"
    width = _num(el.get("strokeWidth"), 1)
    dash = ""
    if el.get("strokeStyle") == "dashed":
        dash = f' stroke-dasharray="{width * 4},{width * 3}"'
    elif el.get("strokeStyle") == "dotted":
        dash = f' stroke-dasharray="{width},{width * 2}"'
    return f' stroke="{stroke}" stroke-width="{width}"{dash}'


def _render_rect_like(el: dict[str, Any]) -> str:
    x, y, w, h = el["x"], el["y"], el.get("width", 0), el.get("height", 0)
    fill = _fill(el)
    opacity = _num(el.get("opacity"), 100) / 100
    common = f' fill="{fill}"{_stroke_attrs(el)} opacity="{opacity}"{_rotation(el)}'

    if el["type"] == "ellipse":
        return f'<ellipse cx="{x + w / 2}" cy="{y + h / 2}" rx="{w / 2}" ry="{h / 2}"{common}/>'
    if el["type"] == "diamond":
        points = f"{x + w / 2},{y} {x + w},{y + h / 2} {x + w / 2},{y + h} {x},{y + h / 2}"
        return f'<polygon points="{points}"{common}/>'
    # rectangle / image placeholder / frame fallback
    rx = min(w, h) * 0.08 if (el.get("roundness")) else 0
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx:.1f}"{common}/>'


def _render_text(el: dict[str, Any]) -> str:
    x, y, w, h = el["x"], el["y"], el.get("width", 0), el.get("height", 0)
    font_size = _num(el.get("fontSize"), 20)
    line_height = _num(el.get("lineHeight"), 1.25)
    color = el.get("strokeColor") or "#1e1e1e"
    align = {"left": "start", "center": "middle", "right": "end"}.get(el.get("textAlign"), "middle")
    anchor_x = {"start": x, "middle": x + w / 2, "end": x + w}[align]
    lines = str(el.get("text", "")).split("\n")
    total_height = len(lines) * font_size * line_height
    start_y = y + (h - total_height) / 2 + font_size * 0.85 if h else y + font_size

    tspans = "".join(
        f'<tspan x="{anchor_x}" y="{start_y + i * font_size * line_height}">{escape(line)}</tspan>'
        for i, line in enumerate(lines)
    )
    return (
        f'<text font-family="sans-serif" font-size="{font_size}" fill="{color}" '
        f'text-anchor="{align}"{_rotation(el)}>{tspans}</text>'
    )


def _render_linear(el: dict[str, Any]) -> str:
    x, y = el["x"], el["y"]
    points = [(x + p[0], y + p[1]) for p in el.get("points", [[0, 0], [0, 0]])]
    if len(points) < 2:
        return ""
    path = f"M {points[0][0]},{points[0][1]} " + " ".join(f"L {px},{py}" for px, py in points[1:])
    stroke = el.get("strokeColor") or "#1e1e1e"
    width = _num(el.get("strokeWidth"), 1)
    parts = [f'<path d="{path}" fill="none" stroke="{stroke}" stroke-width="{width}"{_rotation(el)}/>']

    if el["type"] == "arrow" and el.get("endArrowhead", "triangle") is not None:
        (x2, y2), (x1, y1) = points[-1], points[-2]
        theta = math.atan2(y2 - y1, x2 - x1)
        size = max(8, width * 4)
        spread = math.radians(25)
        for sign in (-1, 1):
            ang = theta + sign * (math.pi - spread)
            parts.append(
                f'<line x1="{x2}" y1="{y2}" x2="{x2 + size * math.cos(ang)}" '
                f'y2="{y2 + size * math.sin(ang)}" stroke="{stroke}" stroke-width="{width}"/>'
            )
    return "".join(parts)


def _render_image(el: dict[str, Any], images: dict[str, tuple[bytes, str]]) -> str:
    file_id = el.get("fileId")
    entry = images.get(file_id) if file_id else None
    if not entry:
        return _render_rect_like({**el, "type": "rectangle", "backgroundColor": "#e0e0e0"})
    data, mime = entry
    href = f"data:{mime};base64,{base64.b64encode(data).decode()}"
    x, y, w, h = el["x"], el["y"], el.get("width", 0), el.get("height", 0)
    return f'<image x="{x}" y="{y}" width="{w}" height="{h}" href="{href}" preserveAspectRatio="none"{_rotation(el)}/>'


def build_svg(
    elements: list[dict[str, Any]],
    images: dict[str, tuple[bytes, str]],
    background_color: str = "#ffffff",
    crop: tuple[float, float, float, float] | None = None,
) -> str:
    """`images` maps fileId -> (raw_bytes, mime_type) for every image element
    to embed (fetch each via ExcalidashClient.get_file first).

    `crop`, if given, is (x, y, width, height) in element coordinates: the
    output raster is exactly that rectangle (no auto-fit padding), and
    anything outside it is simply off-canvas rather than resized to fit —
    used for rendering one region of a drawing instead of the whole scene.
    """
    if crop is not None:
        min_x, min_y, width, height = crop
        offset_x, offset_y = -min_x, -min_y
    else:
        min_x, min_y, max_x, max_y = _bbox(elements)
        width = max_x - min_x + 2 * PADDING
        height = max_y - min_y + 2 * PADDING
        offset_x, offset_y = -min_x + PADDING, -min_y + PADDING

    body_elements = [el for el in elements if not el.get("isDeleted")]
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
        f'width="{width:.0f}" height="{height:.0f}" viewBox="0 0 {width:.0f} {height:.0f}">',
        f'<rect x="0" y="0" width="{width:.0f}" height="{height:.0f}" fill="{background_color}"/>',
        f'<g transform="translate({offset_x},{offset_y})">',
    ]
    for el in body_elements:
        el_type = el.get("type")
        if el_type in ("rectangle", "diamond", "ellipse", "frame"):
            parts.append(_render_rect_like(el))
        elif el_type == "text":
            parts.append(_render_text(el))
        elif el_type in ("arrow", "line"):
            parts.append(_render_linear(el))
        elif el_type == "image":
            parts.append(_render_image(el, images))
        # freedraw and anything else: skipped (rare in agent-authored scenes).
    parts.append("</g></svg>")
    return "".join(parts)
