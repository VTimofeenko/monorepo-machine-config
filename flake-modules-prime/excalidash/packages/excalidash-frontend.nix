/**
  ExcaliDash static frontend (Vite/React SPA).

  Client-side default is `API_URL = "/api"` (frontend/src/api/client.ts), so
  the build is deployment-agnostic — no `VITE_*` backend-URL baking needed.
  `services.excalidash.nginx` (../nixos-module.nix) is what actually serves
  this and splits `/api` + `/socket.io` off to the backend — not upstream's
  own nginx-in-a-container + `nginx.conf.template` placeholder substitution.
*/
{
  lib,
  runCommand,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
}:

let
  version = "0.6.0";

  # Same pin as ./excalidash-backend.nix — kept per-file (rather than
  # shared) since each package here is independently `callPackage`-able;
  # identical rev+hash means Nix only actually fetches it once. `rev =
  # "v${version}"` (not a bare commit hash) is what lets `nix-update
  # excalidash-frontend` bump this on its own.
  excalidashSrc = fetchFromGitHub {
    owner = "ZimengXiong";
    repo = "ExcaliDash";
    rev = "v${version}";
    hash = "sha256-oTLrSJiuhD/FQOayXevbNFlBmgaTvsQqlcZByt/PafM=";
  };
in
buildNpmPackage (finalAttrs: {
  pname = "excalidash-frontend";
  inherit version;

  # `lib.fileset` needs a real `Path` value for `root`/its fileset members;
  # `fetchFromGitHub`'s result is a derivation (a string-like value once
  # interpolated), so compose the two pieces we want with `runCommand`
  # instead — same approach as ../packages/excalidash-backend.nix's `src`.
  src = runCommand "excalidash-frontend-src" { } ''
    mkdir -p $out
    cp -r ${excalidashSrc}/frontend $out/frontend
    cp ${excalidashSrc}/VERSION $out/VERSION
  '';

  sourceRoot = "${finalAttrs.src.name}/frontend";

  nodejs = nodejs_22;

  npmDepsHash = "sha256-Q0NrOfakCI5IrogB9pEP5iZqP4xCAHufrQxo7ra/hFc=";

  # Allows having a global library if auth mode is "disabled".
  # Upstream's own AUTH_MODE=disabled path (backend/src/middleware/auth.ts's
  # `requireAuth`) resolves every request to a fixed bootstrap identity, so
  # `GET/PUT /library` already works with no login — but these three
  # frontend call sites gate library persistence on `user` (from
  # `AuthContext`) being truthy, and `AuthContext.tsx` deliberately sets
  # `user = null` whenever auth is disabled. Net effect: with auth disabled,
  # any library you add only lives in that one editor tab's in-memory
  # Excalidraw state — never saved, never loaded into the next drawing.
  # Threading `authEnabled` (also from `AuthContext`, already exposed) down
  # to these same three spots and OR-ing it into each `user` check turns
  # "persist iff logged in" into "persist iff logged in, or auth is off
  # entirely" — matching what the backend already allows.
  postPatch = ''
    substituteInPlace src/pages/Editor.tsx \
      --replace-fail \
        'const { user } = useAuth();' \
        'const { user, authEnabled } = useAuth();' \
      --replace-fail \
        'useLibraryImportFromUrl({ excalidrawAPIRef: excalidrawAPI, isReady, user });' \
        'useLibraryImportFromUrl({ excalidrawAPIRef: excalidrawAPI, isReady, user, authEnabled });' \
      --replace-fail \
        $'useEditorSceneLoader({\n    id,\n    user,' \
        $'useEditorSceneLoader({\n    id,\n    user,\n    authEnabled,' \
      --replace-fail \
        $'  } = useEditorCommands({\n    autoHideEnabled,\n    canEdit,' \
        $'  } = useEditorCommands({\n    authEnabled,\n    autoHideEnabled,\n    canEdit,'

    substituteInPlace src/pages/editor/useLibraryImportFromUrl.ts \
      --replace-fail \
        $'type UseLibraryImportFromUrlParams = {\n  excalidrawAPIRef: RefObject<any>;' \
        $'type UseLibraryImportFromUrlParams = {\n  authEnabled: boolean | null;\n  excalidrawAPIRef: RefObject<any>;' \
      --replace-fail \
        $'export const useLibraryImportFromUrl = ({\n  excalidrawAPIRef,' \
        $'export const useLibraryImportFromUrl = ({\n  authEnabled,\n  excalidrawAPIRef,' \
      --replace-fail \
        'if (user) {' \
        'if (user || authEnabled === false) {' \
      --replace-fail \
        '}, [excalidrawAPIRef, isReady, user]);' \
        '}, [authEnabled, excalidrawAPIRef, isReady, user]);'

    substituteInPlace src/pages/editor/useEditorSceneLoader.ts \
      --replace-fail \
        $'type SceneLoaderParams = {\n  id: string | undefined;\n  user: unknown;' \
        $'type SceneLoaderParams = {\n  id: string | undefined;\n  user: unknown;\n  authEnabled: boolean | null;' \
      --replace-fail \
        $'export const useEditorSceneLoader = ({\n  id,\n  user,' \
        $'export const useEditorSceneLoader = ({\n  id,\n  user,\n  authEnabled,' \
      --replace-fail \
        'const libraryItemsPromise = userIdKey' \
        'const libraryItemsPromise = userIdKey || authEnabled === false' \
      --replace-fail \
        $'  }, [\n    id,' \
        $'  }, [\n    authEnabled,\n    id,'

    substituteInPlace src/pages/editor/useEditorCommands.ts \
      --replace-fail \
        $'  setNewName: (name: string) => void;\n  user: unknown;\n};' \
        $'  setNewName: (name: string) => void;\n  user: unknown;\n  authEnabled: boolean | null;\n};' \
      --replace-fail \
        $'  setNewName,\n  user,\n}: UseEditorCommandsParams) => {' \
        $'  setNewName,\n  user,\n  authEnabled,\n}: UseEditorCommandsParams) => {' \
      --replace-fail \
        'if (!canEdit || !user) return;' \
        'if (!canEdit || (!user && authEnabled !== false)) return;' \
      --replace-fail \
        '[canEdit, debouncedSaveLibrary, user],' \
        '[authEnabled, canEdit, debouncedSaveLibrary, user],'
  '';

  # `npm run build` is `tsc -b && vite build && copy-excalidraw-assets.mjs --dist`
  # — the default buildNpmPackage build phase (`npm run build`) is fine as-is.

  installPhase = ''
    runHook preInstall
    cp -r dist $out
    runHook postInstall
  '';

  meta = {
    description = "ExcaliDash static frontend (Vite/React SPA)";
    platforms = lib.platforms.linux;
  };
})
