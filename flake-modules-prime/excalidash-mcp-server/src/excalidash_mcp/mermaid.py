"""Mermaid -> Excalidraw element conversion.

Delegates to the `excalidash-mermaid-helper` Node CLI (see
../../mermaid-helper), since the actual parsing/layout lives in
`@excalidraw/mermaid-to-excalidraw`, a browser-oriented JS library with no
Python equivalent. The helper prints a JSON array of elements on stdout.

Known limitation: the helper runs headless (jsdom + fixed-size text-bbox
polyfill, no real font measurement or full `convertToExcalidrawElements`
expansion), so box sizes/label centering are approximate, not pixel-exact
with what Excalidraw's own in-browser renderer would produce. Good enough to
get a real, editable diagram into a drawing — nudge positions in the editor
afterwards if it matters.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
from typing import Any


class MermaidConversionError(RuntimeError):
    pass


def _helper_path() -> str:
    override = os.environ.get("EXCALIDASH_MERMAID_HELPER")
    if override:
        return override
    found = shutil.which("excalidash-mermaid-helper")
    if not found:
        raise MermaidConversionError(
            "excalidash-mermaid-helper not found on PATH "
            "(set EXCALIDASH_MERMAID_HELPER to its path)"
        )
    return found


def mermaid_to_elements(mermaid_text: str) -> list[dict[str, Any]]:
    try:
        result = subprocess.run(
            [_helper_path()],
            input=mermaid_text,
            capture_output=True,
            text=True,
            timeout=30,
        )
    except subprocess.TimeoutExpired as exc:
        raise MermaidConversionError("mermaid conversion timed out") from exc

    if result.returncode != 0:
        raise MermaidConversionError(
            f"mermaid conversion failed: {result.stderr.strip() or result.stdout.strip()}"
        )
    try:
        elements = json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        raise MermaidConversionError(f"helper produced invalid JSON: {exc}") from exc
    if not isinstance(elements, list):
        raise MermaidConversionError("helper did not produce a JSON array of elements")
    return elements
