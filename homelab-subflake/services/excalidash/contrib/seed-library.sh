#!/usr/bin/env bash
#
# Seeds an ExcaliDash instance's shared Excalidraw library from a local
# `.excalidrawlib` file, bypassing the browser entirely.
#
# Why this exists: with `services.excalidash.authMode = "disabled"`, the
# backend already resolves every request to a fixed bootstrap identity
# (`requireAuth` in ExcaliDash's own `backend/src/middleware/auth.ts`), so
# `GET`/`PUT /api/library` work fine unauthenticated. But the frontend gates
# library persistence on its local `user` object being truthy, and its
# `AuthContext` deliberately sets `user = null` whenever auth is disabled —
# so importing a library through the UI only lives in that browser tab's
# in-memory Excalidraw state and is lost on the next page load. This script
# talks to the same `PUT /api/library` endpoint directly, so the library
# persists to the shared bootstrap account and shows up in every drawing.
#
# A `.excalidrawlib` file's `libraryItems` array is already in the exact
# shape the backend stores as-is (no server-side validation of item shape,
# just `Array.isArray`), so no reshaping is needed beyond wrapping it.
#
# Usage: ./seed-library.sh <base-url> <path-to.excalidrawlib>
# Example: ./seed-library.sh https://excalidash.example.com ~/shapes.excalidrawlib

set -euo pipefail

if [ $# -ne 2 ]; then
  echo "Usage: $0 <base-url> <path-to.excalidrawlib>" >&2
  exit 1
fi

base=$1
lib=$2
jar=$(mktemp)
trap 'rm -f "$jar"' EXIT

# 1. Get CSRF token/cookie
resp=$(curl -sf -c "$jar" -b "$jar" "$base/api/csrf-token")
token=$(echo "$resp" | jq -r .token)
hdr=$(echo "$resp" | jq -r .header)

# 2. Build the payload from the library file
payload=$(jq -c '{items: .libraryItems}' "$lib")

# 3. PUT it
curl -sf -b "$jar" \
  -H "Content-Type: application/json" \
  -H "Origin: $base" \
  -H "$hdr: $token" \
  -X PUT "$base/api/library" \
  --data "$payload" | jq

# 4. Confirm it saved
echo "Items now stored: $(curl -sf -b "$jar" "$base/api/library" | jq '.items | length')"
