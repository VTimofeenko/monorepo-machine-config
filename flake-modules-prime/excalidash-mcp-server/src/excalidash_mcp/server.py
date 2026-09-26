from __future__ import annotations

import os
from pathlib import Path
from typing import Any, Literal

from mcp.server.fastmcp import FastMCP, Image

from .client import ExcalidashClient
from .mermaid import mermaid_to_elements
from .render import render_drawing_preview as _render_drawing_preview
from .render import render_drawing_region as _render_drawing_region
from .render import render_frame as _render_frame

mcp = FastMCP(
    "excalidash",
    instructions=(
        "Tools for a self-hosted ExcaliDash instance: list/read/create/update "
        "drawings and collections, and convert Mermaid diagram source into "
        "Excalidraw elements (optionally saving the result directly as a "
        "drawing). Excalidraw elements are plain dicts following the "
        "Excalidraw scene element schema (type, x, y, width, height, ...)."
    ),
)


def _client() -> ExcalidashClient:
    return ExcalidashClient()


@mcp.tool()
def list_collections() -> list[dict[str, Any]]:
    """List the collections in ExcaliDash."""
    return _client().list_collections()


@mcp.tool()
def list_drawings(
    collection_id: str | None = None,
    search: str | None = None,
    limit: int = 50,
) -> dict[str, Any]:
    """List drawings (name/id/collection/timestamps only, no element data).

    Pass `collection_id` to scope to one collection, or omit to list drawings
    outside the trash. Use `search` to filter by name substring.
    """
    return _client().list_drawings(collection_id=collection_id, search=search, limit=limit)


@mcp.tool()
def get_drawing(drawing_id: str, include_assets: bool = False) -> dict[str, Any]:
    """Fetch a drawing's scene: name, elements, appState, version.

    `include_assets=False` (default) omits `preview` (a derived, often-stale
    rendered thumbnail) and `files` (embedded image data — can be huge on
    scenes with photos) since most reads only care about element layout.
    Pass True to get those back, then use get_file to fetch a specific
    image's bytes without repeating the whole scene.
    """
    return _client().get_drawing(drawing_id, include_assets=include_assets)


@mcp.tool()
def get_file(drawing_id: str, file_id: str) -> Any:
    """Fetch one embedded file's raw bytes (file ids come from a drawing's
    `files` map — call get_drawing(..., include_assets=True) to see them).
    Returns an image content block for image/* files, else a note with the
    mime type (binary content that isn't an image isn't inlined).
    """
    data, mime_type = _client().get_file(drawing_id, file_id)
    if mime_type.startswith("image/"):
        return Image(data=data, format=mime_type.removeprefix("image/"))
    return f"file {file_id} is {mime_type}, {len(data)} bytes (not an image, not inlined)"


@mcp.tool()
def create_drawing(
    name: str,
    elements: list[dict[str, Any]],
    collection_id: str | None = None,
) -> dict[str, Any]:
    """Create a new drawing from a list of Excalidraw elements.

    `elements` should be plain Excalidraw scene elements (each at least
    `type`, `x`, `y`, `width`, `height`, `id`); missing cosmetic fields
    (seed, roughness, stroke/fill colors, ...) are filled in with defaults
    by the Excalidraw client when the drawing is opened.
    """
    return _client().create_drawing(name=name, elements=elements, collection_id=collection_id)


@mcp.tool()
def update_drawing_elements(
    drawing_id: str,
    elements: list[dict[str, Any]],
    version: int | None = None,
) -> dict[str, Any]:
    """Replace a drawing's ENTIRE element array with `elements` — this is a
    full overwrite, not a merge. Any element from the current scene that
    isn't in `elements` is gone. To change specific elements without risking
    dropping the rest, use patch_elements instead. Pass `version` (from
    get_drawing) to avoid clobbering a concurrent edit; omitted, the write
    is unconditional.
    """
    return _client().update_drawing(drawing_id, elements=elements, version=version)


@mcp.tool()
def patch_elements(
    drawing_id: str,
    patches: dict[str, dict[str, Any]],
) -> dict[str, Any]:
    """Shallow-merge properties into one or more existing elements by id,
    leaving every other element untouched. This is the safe way to do
    small edits ("make this box purple", "move this arrow's endpoint") —
    it fetches the current scene, merges, and writes back in one call, so
    you never have to resend (or risk dropping) the rest of the drawing.

    `patches` maps element id -> the properties to merge into it, e.g.
    {"abc123": {"backgroundColor": "#a855f7"}}. Get element ids and their
    current properties from get_drawing. Errors if any id doesn't exist in
    the drawing.
    """
    return _client().patch_elements(drawing_id, patches)


@mcp.tool()
def add_elements(drawing_id: str, elements: list[dict[str, Any]]) -> dict[str, Any]:
    """Append new elements to a drawing's existing scene (e.g. new shapes
    from mermaid_to_excalidraw). Unlike update_drawing_elements, this does
    not touch what's already there — no need to resend existing elements.
    Errors if any given element's id collides with an existing one.
    """
    return _client().add_elements(drawing_id, elements)


@mcp.tool()
def add_shape(
    drawing_id: str,
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
) -> dict[str, Any]:
    """Add one shape from a bounding box, instead of hand-assembling a raw
    Excalidraw element dict. `shape_type` is one of "rectangle", "diamond",
    "ellipse", "arrow", "line", "text".

    For rectangle/diamond/ellipse: (x, y, width, height) is the usual
    top-left + size box; pass `text` to also add a centered bound label in
    one call (creates and binds a second text element for you).

    For arrow/line: (x, y) is the start point and (x + width, y + height)
    the end point — a straight two-point line (`text` is ignored; for a
    labeled, *bound* arrow between two existing shapes use connect instead).

    For text: (x, y, width, height) is the text box; `text` is its content.

    Only the fields that actually matter are set — cosmetic ones (seed,
    roughness, ...) are left for Excalidraw's own client to default in when
    the drawing is opened, same as create_drawing.
    """
    return _client().add_shape(
        drawing_id,
        shape_type,
        x,
        y,
        width,
        height,
        text=text,
        stroke_color=stroke_color,
        background_color=background_color,
        stroke_width=stroke_width,
        font_size=font_size,
    )


@mcp.tool()
def move_node(drawing_id: str, element_id: str, x: float, y: float) -> dict[str, Any]:
    """Move a node (rectangle/diamond/ellipse/image/frame/text) to (x, y)
    (top-left corner, same convention as the element's own x/y) and
    automatically re-route every arrow bound to it, plus its own bound
    label if any, so connections stay attached instead of pointing at
    stale coordinates. Arrow routing is a straight line clipped to each
    endpoint's shape boundary — good enough to keep things connected, not
    guaranteed to match Excalidraw's own elbow routing exactly.
    """
    return _client().move_node(drawing_id, element_id, x, y)


@mcp.tool()
def connect(
    drawing_id: str,
    source_id: str,
    target_id: str,
    label: str | None = None,
) -> dict[str, Any]:
    """Add a new arrow bound from source_id to target_id (routed/clipped the
    same way move_node re-routes existing arrows), with an optional label.
    Use this instead of hand-building an arrow element with startBinding/
    endBinding/points yourself.
    """
    updated, _arrow_id = _client().connect(drawing_id, source_id, target_id, label)
    return updated


@mcp.tool()
def disconnect(drawing_id: str, arrow_id: str) -> dict[str, Any]:
    """Remove an arrow (edge) by id, cleaning up the boundElements
    references on the shapes it connected. Equivalent to delete_element on
    an arrow — provided under this name for symmetry with connect."""
    return _client().delete_element(drawing_id, arrow_id)


@mcp.tool()
def delete_element(drawing_id: str, element_id: str) -> dict[str, Any]:
    """Delete one element (node, arrow, or standalone text) and cascade the
    reference cleanup: any arrow bound to a deleted node is unbound (not
    itself deleted) rather than left pointing at a nonexistent id, and a
    deleted element's own bound label (if any) is deleted with it. Prevents
    the dangling-reference risk of removing an element by hand via
    patch_elements/update_drawing_elements.
    """
    return _client().delete_element(drawing_id, element_id)


@mcp.tool()
def get_connections(drawing_id: str, element_id: str) -> list[dict[str, Any]]:
    """List the arrows attached to a node: for each, which arrow id, the
    direction ("in"/"out" relative to element_id), the id of the element on
    the other end, and the arrow's label text if it has one. Answers "what
    feeds into/out of X" without scanning every arrow's bindings by hand.
    """
    return _client().get_connections(drawing_id, element_id)


@mcp.tool()
def render_drawing_preview(drawing_id: str, output_path: str | None = None) -> Any:
    """Render a drawing (including embedded images) to a PNG, composited
    from get_drawing's elements + get_file's image bytes — no browser, no
    login session, just the existing API key.

    Use this instead of trusting the `preview` field from get_drawing: that
    field is a client-generated SVG with a known bug where an image element
    can flatten into a full-canvas background, losing the rest of the
    scene. Trade-off: this renders flat shapes, not Excalidraw's hand-drawn
    "rough" style — good for verifying layout/content, not a substitute for
    opening the real editor if the sketchy styling itself matters.

    By default returns the PNG inline as an image content block. Pass
    `output_path` (an absolute path, or one relative to wherever this MCP
    server process runs — typically the same machine as its client, since
    it's normally launched as a local subprocess) to instead write the file
    there and get back a short confirmation with the resolved path and
    byte size — useful to hand the file to another local tool instead of
    inlining it into the conversation.
    """
    png_bytes = _render_drawing_preview(_client(), drawing_id)
    if output_path is not None:
        path = Path(output_path).expanduser().resolve()
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(png_bytes)
        return f"Saved to {path} ({len(png_bytes)} bytes)"
    return Image(data=png_bytes, format="png")


@mcp.tool()
def render_region(
    drawing_id: str,
    x: float,
    y: float,
    width: float,
    height: float,
    output_path: str | None = None,
) -> Any:
    """Render just a rectangular region of a drawing to a PNG, in the same
    element coordinate space as get_drawing/get_connections/extract_frame
    (not screen pixels) — instead of the whole scene. Use this to zoom into
    one cluster of elements on a large diagram (e.g. after get_connections
    or extract_frame gives you a bounding area of interest) without paying
    the token/byte cost of a full render_drawing_preview.

    Same output_path behavior as render_drawing_preview: pass it to write
    the PNG to a file and get back a short confirmation instead of an
    inline image content block.
    """
    png_bytes = _render_drawing_region(_client(), drawing_id, x, y, width, height)
    if output_path is not None:
        path = Path(output_path).expanduser().resolve()
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(png_bytes)
        return f"Saved to {path} ({len(png_bytes)} bytes)"
    return Image(data=png_bytes, format="png")


@mcp.tool()
def extract_frame(drawing_id: str, frame: str, include_deleted: bool = False) -> dict[str, Any]:
    """Get everything grouped into a frame element, by its id OR its
    human-readable name (the label shown above a frame in the editor,
    matched case-insensitively — e.g. "Sketch"). Errors if the name matches
    more than one frame; pass the id instead in that case.

    Returns the frame itself (name, x/y/width/height), every element whose
    `frameId` points at it, and `images`: a flat [{"id", "fileId"}, ...] list
    of just the image elements among them, so you can grab fileIds straight
    from it for get_file without re-scanning `elements` by hand.

    `include_deleted=False` (default) excludes members Excalidraw has marked
    `isDeleted` (kept around internally for undo, not actually on the
    canvas) — pass True to see those too.

    Prefer render_frame if you just want to *see* the frame's contents —
    it does the same lookup and renders directly, skipping this call.
    """
    return _client().get_frame_elements(drawing_id, frame, include_deleted=include_deleted)


@mcp.tool()
def render_frame(drawing_id: str, frame: str, output_path: str | None = None) -> Any:
    """Render one frame's contents to PNG directly, by its id or its
    human-readable name (e.g. "Sketch") — the single-call replacement for
    extract_frame + render_region when you already know which frame you
    want to look at instead of its raw coordinates. Only downloads the
    embedded images that actually fall inside the frame, not the whole
    drawing's photos.

    Same output_path behavior as render_drawing_preview/render_region: pass
    it to write the PNG to a file and get back a short confirmation instead
    of an inline image content block.
    """
    png_bytes = _render_frame(_client(), drawing_id, frame)
    if output_path is not None:
        path = Path(output_path).expanduser().resolve()
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(png_bytes)
        return f"Saved to {path} ({len(png_bytes)} bytes)"
    return Image(data=png_bytes, format="png")


@mcp.tool()
def rename_drawing(drawing_id: str, name: str) -> dict[str, Any]:
    """Rename a drawing without touching its elements."""
    return _client().update_drawing(drawing_id, name=name)


@mcp.tool()
def mermaid_to_excalidraw(mermaid: str) -> list[dict[str, Any]]:
    """Convert Mermaid diagram source (flowchart/sequence/class/...) to a
    list of Excalidraw elements, without saving anything. Useful to inspect
    or hand-edit the result before calling create_drawing.

    Conversion runs headless (no browser), so text box sizing/centering is
    approximate — treat the result as a good starting layout, not final.
    """
    return mermaid_to_elements(mermaid)


@mcp.tool()
def create_drawing_from_mermaid(
    name: str,
    mermaid: str,
    collection_id: str | None = None,
) -> dict[str, Any]:
    """Convert Mermaid source to Excalidraw elements and save it as a new
    drawing in one step. See mermaid_to_excalidraw for the conversion caveat.
    """
    elements = mermaid_to_elements(mermaid)
    return _client().create_drawing(name=name, elements=elements, collection_id=collection_id)


def main() -> None:
    transport: Literal["stdio", "sse", "streamable-http"] = os.environ.get(
        "EXCALIDASH_MCP_TRANSPORT", "stdio"
    )  # type: ignore[assignment]
    mcp.settings.host = os.environ.get("EXCALIDASH_MCP_HOST", "127.0.0.1")
    mcp.settings.port = int(os.environ.get("EXCALIDASH_MCP_PORT", "8000"))
    mcp.run(transport=transport)


if __name__ == "__main__":
    main()
