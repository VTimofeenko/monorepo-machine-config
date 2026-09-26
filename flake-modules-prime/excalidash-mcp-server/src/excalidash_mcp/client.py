"""Thin client for the ExcaliDash dashboard REST API.

Auth: a scoped API key (Settings -> API Keys in ExcaliDash), sent as
`Authorization: Bearer <key>`. Needs `drawings:read`/`drawings:write` and,
for collection listing/creation, `collections:read`/`collections:write`.
"""

from __future__ import annotations

import os
from typing import Any, Callable

import httpx

from . import graph


class ExcalidashError(RuntimeError):
    pass


class ExcalidashClient:
    def __init__(self, base_url: str | None = None, api_key: str | None = None) -> None:
        base_url = base_url or os.environ.get("EXCALIDASH_URL")
        api_key = api_key or os.environ.get("EXCALIDASH_API_KEY")
        if not base_url:
            raise ExcalidashError("EXCALIDASH_URL is not set")
        if not api_key:
            raise ExcalidashError("EXCALIDASH_API_KEY is not set")

        self._client = httpx.Client(
            base_url=base_url.rstrip("/"),
            headers={"Authorization": f"Bearer {api_key}"},
            timeout=30.0,
        )

    def close(self) -> None:
        self._client.close()

    def _request(self, method: str, path: str, **kwargs: Any) -> Any:
        response = self._client.request(method, path, **kwargs)
        if response.status_code >= 400:
            try:
                detail = response.json()
            except ValueError:
                detail = response.text
            raise ExcalidashError(f"{method} {path} -> HTTP {response.status_code}: {detail}")
        if not response.content:
            return {}
        return response.json()

    def list_collections(self) -> list[dict[str, Any]]:
        # GET /collections returns a bare JSON array, unlike every other
        # list endpoint here (which wrap in {"...": [...], "totalCount": ...}).
        return self._request("GET", "/collections")

    def create_collection(self, name: str) -> dict[str, Any]:
        return self._request("POST", "/collections", json={"name": name})

    def list_drawings(
        self,
        *,
        collection_id: str | None = None,
        search: str | None = None,
        limit: int = 50,
        offset: int = 0,
    ) -> dict[str, Any]:
        params: dict[str, Any] = {"limit": limit, "offset": offset}
        if collection_id is not None:
            params["collectionId"] = collection_id
        if search:
            params["search"] = search
        return self._request("GET", "/drawings", params=params)

    def get_drawing(self, drawing_id: str, *, include_assets: bool = False) -> dict[str, Any]:
        """`include_assets=False` (default) drops `preview` and `files` —
        those are the two large/derived fields (embedded base64 images,
        a rendered thumbnail); most callers only want `elements`/`appState`
        to reason about layout. Pass True to get everything, e.g. before
        calling get_file.
        """
        drawing = self._request("GET", f"/drawings/{drawing_id}")
        if not include_assets:
            drawing.pop("preview", None)
            drawing.pop("files", None)
        return drawing

    def get_file(self, drawing_id: str, file_id: str) -> tuple[bytes, str]:
        """Fetches one embedded file's raw bytes directly (bypassing the
        `files` map's dataURL entirely, which get_drawing omits by default
        anyway) — returns (bytes, mime_type).

        Known upstream limitation (ExcaliDash, not this client): API keys
        can't reach `/files/*` at all today — `getApiKeyRouteResource` in
        the backend's `middleware/auth.ts` only recognizes `drawings` and
        `collections` path prefixes, so this 404s ("File not found") for a
        private drawing even with the right scopes and even though a
        session cookie would see the same file fine. Same story in reverse
        for uploading (`PUT /drawings/:id/files/:fileId` 403s an API key
        outright). Fixing this needs an upstream backend change; nothing to
        do here in the MCP client.
        """
        response = self._client.get(f"/files/{drawing_id}/{file_id}")
        if response.status_code >= 400:
            raise ExcalidashError(
                f"GET /files/{drawing_id}/{file_id} -> HTTP {response.status_code}: {response.text}"
            )
        mime_type = response.headers.get("content-type", "application/octet-stream").split(";")[0]
        return response.content, mime_type

    def create_drawing(
        self,
        *,
        name: str,
        elements: list[dict[str, Any]],
        collection_id: str | None = None,
    ) -> dict[str, Any]:
        payload: dict[str, Any] = {"name": name, "elements": elements}
        if collection_id is not None:
            payload["collectionId"] = collection_id
        return self._request("POST", "/drawings", json=payload)

    def update_drawing(
        self,
        drawing_id: str,
        *,
        elements: list[dict[str, Any]] | None = None,
        name: str | None = None,
        version: int | None = None,
    ) -> dict[str, Any]:
        payload: dict[str, Any] = {}
        if elements is not None:
            payload["elements"] = elements
        if name is not None:
            payload["name"] = name
        if version is not None:
            payload["version"] = version
        return self._request("PUT", f"/drawings/{drawing_id}", json=payload)

    def patch_elements(
        self,
        drawing_id: str,
        patches: dict[str, dict[str, Any]],
    ) -> dict[str, Any]:
        """Shallow-merge `patches[element_id]` into each matching element,
        leaving every other element (and every other property of a patched
        element) untouched. Does the read-modify-write itself, in one call,
        so a caller never has to fetch/resend the whole scene just to tweak
        one element's properties.
        """
        current = self.get_drawing(drawing_id)
        elements: list[dict[str, Any]] = current["elements"]
        by_id = {el.get("id"): i for i, el in enumerate(elements)}

        missing = [element_id for element_id in patches if element_id not in by_id]
        if missing:
            raise ExcalidashError(
                f"drawing {drawing_id} has no element(s) with id: {', '.join(missing)}"
            )

        for element_id, props in patches.items():
            index = by_id[element_id]
            elements[index] = {**elements[index], **props}

        return self.update_drawing(
            drawing_id, elements=elements, version=current.get("version")
        )

    def _read_modify_write(
        self,
        drawing_id: str,
        mutate: Callable[[list[dict[str, Any]]], Any],
    ) -> tuple[dict[str, Any], Any]:
        current = self.get_drawing(drawing_id)
        elements: list[dict[str, Any]] = current["elements"]
        result = mutate(elements)
        updated = self.update_drawing(drawing_id, elements=elements, version=current.get("version"))
        return updated, result

    def add_elements(self, drawing_id: str, new_elements: list[dict[str, Any]]) -> dict[str, Any]:
        """Appends `new_elements` to the drawing's existing scene, instead
        of requiring the caller to resend every existing element just to
        add a couple more (the same full-replace risk patch_elements avoids
        for edits, on the "append" side).
        """

        def _append(elements: list[dict[str, Any]]) -> None:
            existing_ids = {el.get("id") for el in elements}
            colliding = existing_ids & {el.get("id") for el in new_elements}
            if colliding:
                raise ExcalidashError(f"element id(s) already exist in drawing: {', '.join(colliding)}")
            elements.extend(new_elements)

        updated, _ = self._read_modify_write(drawing_id, _append)
        return updated

    def add_shape(
        self,
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
        new_elements = graph.new_shape(
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
        return self.add_elements(drawing_id, new_elements)

    def move_node(self, drawing_id: str, element_id: str, x: float, y: float) -> dict[str, Any]:
        updated, _ = self._read_modify_write(
            drawing_id, lambda elements: graph.move_node(elements, element_id, x, y)
        )
        return updated

    def connect(
        self,
        drawing_id: str,
        source_id: str,
        target_id: str,
        label: str | None = None,
    ) -> tuple[dict[str, Any], str]:
        arrow_id_box: list[str] = []

        def _connect(elements: list[dict[str, Any]]) -> None:
            _, arrow_id = graph.connect(elements, source_id, target_id, label)
            arrow_id_box.append(arrow_id)

        updated, _ = self._read_modify_write(drawing_id, _connect)
        return updated, arrow_id_box[0]

    def delete_element(self, drawing_id: str, element_id: str) -> dict[str, Any]:
        current = self.get_drawing(drawing_id)
        new_elements = graph.delete_element(current["elements"], element_id)
        return self.update_drawing(drawing_id, elements=new_elements, version=current.get("version"))

    def get_connections(self, drawing_id: str, element_id: str) -> list[dict[str, Any]]:
        current = self.get_drawing(drawing_id)
        return graph.get_connections(current["elements"], element_id)

    def get_frame_elements(
        self, drawing_id: str, frame_ref: str, include_deleted: bool = False
    ) -> dict[str, Any]:
        current = self.get_drawing(drawing_id)
        return graph.get_frame_elements(current["elements"], frame_ref, include_deleted=include_deleted)
