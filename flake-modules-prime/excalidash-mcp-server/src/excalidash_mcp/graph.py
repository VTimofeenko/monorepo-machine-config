"""Graph-level operations on an Excalidraw element list: treat rectangles/
diamonds/ellipses/etc. as nodes and arrows as bound edges, instead of making
every caller hand-compute geometry and keep bindings consistent by hand.

All functions mutate/return a plain list of element dicts (the same shape
`get_drawing`/`create_drawing` use) — no ExcaliDash API calls happen here.
"""

from __future__ import annotations

import math
import random
from typing import Any

NODE_TYPES = {"rectangle", "diamond", "ellipse", "image", "frame"}
ARROW_GAP = 4.0


class GraphError(RuntimeError):
    pass


def _rand_id() -> str:
    return "".join(random.choices("abcdefghijklmnopqrstuvwxyz0123456789", k=12))


def _index_by_id(elements: list[dict[str, Any]]) -> dict[str, int]:
    return {el.get("id"): i for i, el in enumerate(elements) if el.get("id")}


def _text_label(container_id: str, text: str, cx: float, cy: float, font_size: float = 20) -> dict[str, Any]:
    """A bound text element centered at (cx, cy) — a rough estimate of its
    own size from character count, not real font metrics (same approximation
    mermaid.py's conversion already makes)."""
    text_width = max(20.0, len(text) * font_size * 0.55)
    text_height = font_size * 1.25
    return {
        "id": _rand_id(),
        "type": "text",
        "x": cx - text_width / 2,
        "y": cy - text_height / 2,
        "width": text_width,
        "height": text_height,
        "text": text,
        "originalText": text,
        "fontSize": font_size,
        "fontFamily": 1,
        "textAlign": "center",
        "verticalAlign": "middle",
        "containerId": container_id,
        "boundElements": [],
    }


def _center(el: dict[str, Any]) -> tuple[float, float]:
    return (el["x"] + el.get("width", 0) / 2, el["y"] + el.get("height", 0) / 2)


def _clip_to_rect(el: dict[str, Any], from_point: tuple[float, float]) -> tuple[float, float]:
    """Point where the segment from `from_point` to el's center crosses el's
    boundary (falls back to the center if `from_point` is inside/degenerate).
    """
    cx, cy = _center(el)
    dx, dy = cx - from_point[0], cy - from_point[1]
    if dx == 0 and dy == 0:
        return (cx, cy)
    hw, hh = el.get("width", 0) / 2, el.get("height", 0) / 2
    if hw == 0 or hh == 0:
        return (cx, cy)
    # Scale factor to hit the rectangle boundary along (dx, dy) from center.
    scale = 1 / max(abs(dx) / hw, abs(dy) / hh, 1e-9)
    return (cx - dx * scale, cy - dy * scale)


def _offset_along(point: tuple[float, float], towards: tuple[float, float], distance: float) -> tuple[float, float]:
    dx, dy = towards[0] - point[0], towards[1] - point[1]
    length = math.hypot(dx, dy)
    if length < 1e-9:
        return point
    return (point[0] + dx / length * distance, point[1] + dy / length * distance)


def _endpoint(el: dict[str, Any], other_anchor: tuple[float, float], bound: bool) -> tuple[float, float]:
    if not bound:
        return other_anchor
    edge_point = _clip_to_rect(el, other_anchor)
    # Pull back slightly (gap) so the arrow doesn't touch the shape's edge.
    return _offset_along(edge_point, _center(el), -ARROW_GAP)


def reroute_arrow(arrow: dict[str, Any], elements_by_id: dict[str, dict[str, Any]]) -> None:
    """Recompute an arrow's x/y/points from its bound elements' *current*
    positions. Mutates `arrow` in place. Simplifies to a straight two-point
    arrow (drops any elbow points) — consistent with this server's other
    approximations (see mermaid.py); nudge in the editor if exact routing
    through multiple points matters.
    """
    start_binding = arrow.get("startBinding")
    end_binding = arrow.get("endBinding")
    start_el = elements_by_id.get(start_binding["elementId"]) if start_binding else None
    end_el = elements_by_id.get(end_binding["elementId"]) if end_binding else None

    if start_el is None and end_el is None:
        return  # unbound arrow; nothing to reroute

    start_anchor = _center(start_el) if start_el else (arrow["x"] + arrow["points"][0][0], arrow["y"] + arrow["points"][0][1])
    end_anchor = _center(end_el) if end_el else (arrow["x"] + arrow["points"][-1][0], arrow["y"] + arrow["points"][-1][1])

    start_point = _endpoint(start_el, end_anchor, bound=start_el is not None)
    end_point = _endpoint(end_el, start_anchor, bound=end_el is not None)

    arrow["x"], arrow["y"] = start_point
    arrow["points"] = [[0, 0], [end_point[0] - start_point[0], end_point[1] - start_point[1]]]
    arrow["width"] = abs(end_point[0] - start_point[0])
    arrow["height"] = abs(end_point[1] - start_point[1])


def move_node(elements: list[dict[str, Any]], element_id: str, x: float, y: float) -> list[dict[str, Any]]:
    by_id = _index_by_id(elements)
    if element_id not in by_id:
        raise GraphError(f"no element with id {element_id!r}")
    node = elements[by_id[element_id]]
    if node.get("type") not in NODE_TYPES and node.get("type") != "text":
        raise GraphError(f"element {element_id!r} is a {node.get('type')!r}, not a movable node")

    dx, dy = x - node["x"], y - node["y"]
    node["x"], node["y"] = x, y

    elements_by_id = {el["id"]: el for el in elements if el.get("id")}
    for el in elements:
        # Bound labels move rigidly with their container/arrow.
        if el.get("type") == "text" and el.get("containerId") == element_id:
            el["x"] += dx
            el["y"] += dy
        if el.get("type") == "arrow":
            bindings = (el.get("startBinding"), el.get("endBinding"))
            if any(b and b.get("elementId") == element_id for b in bindings):
                reroute_arrow(el, elements_by_id)
    return elements


def connect(
    elements: list[dict[str, Any]],
    source_id: str,
    target_id: str,
    label: str | None = None,
) -> tuple[list[dict[str, Any]], str]:
    """Appends a new arrow bound from source_id to target_id (with an
    optional bound label), routed with the same rect-clip geometry
    move_node uses. Returns (elements, new_arrow_id).
    """
    by_id = {el["id"]: el for el in elements if el.get("id")}
    if source_id not in by_id:
        raise GraphError(f"no element with id {source_id!r}")
    if target_id not in by_id:
        raise GraphError(f"no element with id {target_id!r}")

    arrow_id = _rand_id()
    arrow: dict[str, Any] = {
        "id": arrow_id,
        "type": "arrow",
        "x": 0,
        "y": 0,
        "width": 0,
        "height": 0,
        "points": [[0, 0], [0, 0]],
        "startBinding": {"elementId": source_id, "focus": 0, "gap": ARROW_GAP},
        "endBinding": {"elementId": target_id, "focus": 0, "gap": ARROW_GAP},
        "boundElements": [],
    }
    reroute_arrow(arrow, by_id)

    for node_id in (source_id, target_id):
        by_id[node_id].setdefault("boundElements", [])
        by_id[node_id]["boundElements"].append({"id": arrow_id, "type": "arrow"})

    elements.append(arrow)

    if label:
        cx = arrow["x"] + arrow["points"][-1][0] / 2
        cy = arrow["y"] + arrow["points"][-1][1] / 2
        text_el = _text_label(arrow_id, label, cx, cy)
        elements.append(text_el)
        arrow["boundElements"].append({"id": text_el["id"], "type": "text"})

    return elements, arrow_id


SHAPE_TYPES = {"rectangle", "diamond", "ellipse"}
LINEAR_TYPES = {"arrow", "line"}


def new_shape(
    shape_type: str,
    x: float,
    y: float,
    width: float,
    height: float,
    text: str | None = None,
    stroke_color: str = "#1e1e1e",
    background_color: str = "transparent",
    stroke_width: float = 2,
    font_size: float = 20,
) -> list[dict[str, Any]]:
    """Builds a shape (or a standalone text element) from a bounding box,
    with sensible defaults — an id, and for rectangle/diamond/ellipse an
    optional centered bound label — instead of requiring a caller to
    hand-assemble a raw element dict (and, for a label, a second bound text
    element wired up via boundElements/containerId themselves).

    For `arrow`/`line`: (x, y) is the start point and (x + width, y + height)
    the end point — a straight two-point line/arrow. `text` is ignored for
    these (arrows get their label via connect, which also handles binding).

    Returns a list of one or two elements (the shape, plus its label text
    element if `text` was given) — pass straight to ExcalidashClient.add_elements.
    """
    if shape_type not in SHAPE_TYPES | LINEAR_TYPES | {"text"}:
        raise GraphError(f"unknown shape_type {shape_type!r}")

    shape_id = _rand_id()

    if shape_type in LINEAR_TYPES:
        element = {
            "id": shape_id,
            "type": shape_type,
            "x": x,
            "y": y,
            "width": abs(width),
            "height": abs(height),
            "points": [[0, 0], [width, height]],
            "strokeColor": stroke_color,
            "strokeWidth": stroke_width,
            "boundElements": [],
        }
        return [element]

    if shape_type == "text":
        return [
            {
                "id": shape_id,
                "type": "text",
                "x": x,
                "y": y,
                "width": width,
                "height": height,
                "text": text or "",
                "originalText": text or "",
                "fontSize": font_size,
                "fontFamily": 1,
                "textAlign": "left",
                "verticalAlign": "top",
                "strokeColor": stroke_color,
            }
        ]

    element = {
        "id": shape_id,
        "type": shape_type,
        "x": x,
        "y": y,
        "width": width,
        "height": height,
        "strokeColor": stroke_color,
        "backgroundColor": background_color,
        "strokeWidth": stroke_width,
        "boundElements": [],
    }
    if not text:
        return [element]

    label_el = _text_label(shape_id, text, x + width / 2, y + height / 2, font_size)
    element["boundElements"].append({"id": label_el["id"], "type": "text"})
    return [element, label_el]


def delete_element(elements: list[dict[str, Any]], element_id: str) -> list[dict[str, Any]]:
    """Removes an element and cascades reference cleanup: any arrow bound to
    a deleted node is unbound (not deleted — the arrow itself still exists,
    just no longer attached); deleting an arrow or a bound text label also
    strips the corresponding `boundElements` entry from whatever referenced
    it. Prevents the dangling-reference bug reported when this was done by
    hand via patch_elements.
    """
    by_id = _index_by_id(elements)
    if element_id not in by_id:
        raise GraphError(f"no element with id {element_id!r}")

    to_delete = {element_id}
    target = elements[by_id[element_id]]
    # A container's/arrow's own bound text label has no purpose without it.
    for bound in target.get("boundElements") or []:
        if bound.get("type") == "text":
            to_delete.add(bound["id"])

    remaining = []
    for el in elements:
        if el.get("id") in to_delete:
            continue
        if el.get("type") == "arrow":
            for key in ("startBinding", "endBinding"):
                binding = el.get(key)
                if binding and binding.get("elementId") in to_delete:
                    el[key] = None
        if el.get("boundElements"):
            el["boundElements"] = [b for b in el["boundElements"] if b.get("id") not in to_delete]
        remaining.append(el)
    return remaining


def find_frame(elements: list[dict[str, Any]], frame_ref: str) -> dict[str, Any]:
    """Resolves `frame_ref` to a frame element, accepting either its id or
    its human-readable name (the label shown above a frame in the editor,
    matched case-insensitively) — so callers can say "Sketch" instead of
    first fetching the whole scene to look up an opaque id.
    """
    by_id = _index_by_id(elements)
    if frame_ref in by_id:
        candidate = elements[by_id[frame_ref]]
        if candidate.get("type") != "frame":
            raise GraphError(f"element {frame_ref!r} is a {candidate.get('type')!r}, not a frame")
        return candidate

    matches = [
        el
        for el in elements
        if el.get("type") == "frame" and (el.get("name") or "").casefold() == frame_ref.casefold()
    ]
    if not matches:
        raise GraphError(f"no frame with id or name {frame_ref!r}")
    if len(matches) > 1:
        ids = ", ".join(m["id"] for m in matches)
        raise GraphError(f"multiple frames named {frame_ref!r} ({ids}) — pass the id instead")
    return matches[0]


def get_frame_elements(
    elements: list[dict[str, Any]], frame_ref: str, include_deleted: bool = False
) -> dict[str, Any]:
    """Returns the frame element, every element assigned to it via `frameId`
    (the grouping Excalidraw's own "frame" tool sets when something is
    dragged into one), and a summary of the image elements among them —
    `frame_ref` may be the frame's id or its name (see find_frame). Saves a
    caller from having to fetch the whole scene, filter by frameId, and
    separately scan for image fileIds by hand just to see/operate on one
    group.

    `include_deleted=False` (default) excludes members with `isDeleted` set
    — Excalidraw keeps deleted elements around (e.g. for undo) rather than
    removing them outright, so without this a frame's contents would look
    like they still include things no longer actually on the canvas. Pass
    True to see those too.
    """
    frame = find_frame(elements, frame_ref)
    frame_id = frame["id"]
    members = [
        el
        for el in elements
        if el.get("frameId") == frame_id and (include_deleted or not el.get("isDeleted"))
    ]
    images = [
        {"id": el["id"], "fileId": el.get("fileId")} for el in members if el.get("type") == "image"
    ]
    return {"frame": frame, "elements": members, "images": images}


def get_connections(elements: list[dict[str, Any]], element_id: str) -> list[dict[str, Any]]:
    by_id = _index_by_id(elements)
    if element_id not in by_id:
        raise GraphError(f"no element with id {element_id!r}")

    label_by_container = {
        el["containerId"]: el.get("text")
        for el in elements
        if el.get("type") == "text" and el.get("containerId")
    }

    connections = []
    for el in elements:
        if el.get("type") != "arrow":
            continue
        start = (el.get("startBinding") or {}).get("elementId")
        end = (el.get("endBinding") or {}).get("elementId")
        if start == element_id and end:
            connections.append({"arrow_id": el["id"], "direction": "out", "other_id": end, "label": label_by_container.get(el["id"])})
        elif end == element_id and start:
            connections.append({"arrow_id": el["id"], "direction": "in", "other_id": start, "label": label_by_container.get(el["id"])})
    return connections
