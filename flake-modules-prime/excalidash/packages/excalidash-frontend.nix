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
  nodejs_24,
}:

let
  version = "0.7.0";

  # Same pin as ./excalidash-backend.nix — kept per-file (rather than
  # shared) since each package here is independently `callPackage`-able;
  # identical rev+hash means Nix only actually fetches it once. `rev =
  # "v${version}"` (not a bare commit hash) is what lets `nix-update
  # excalidash-frontend` bump this on its own.
  excalidashSrc = fetchFromGitHub {
    owner = "ZimengXiong";
    repo = "ExcaliDash";
    rev = "v${version}";
    hash = "sha256-AQZhzsd1aZ8Z0NCfgoCeY4Nwb7IDK8bql++is0g0MVA=";
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

  nodejs = nodejs_24;

  npmDepsHash = "sha256-6gkzqyHL54DTvbbAaXy4CH5LXeujeRL2NJ+5WCQ0OyE=";

  # Allows having a global library if auth mode is "disabled".
  # Upstream's own AUTH_MODE=disabled path (backend/src/middleware/auth.ts's
  # `requireAuth`) resolves every request to a fixed bootstrap identity, so
  # `GET/PUT /library` already works with no login — but the frontend gates
  # library persistence on `user` (from `AuthContext`) being truthy, and
  # `AuthContext.tsx` deliberately sets `user = null` whenever auth is
  # disabled. Net effect: with auth disabled, any library you add only lives
  # in that one editor tab's in-memory Excalidraw state — never saved, never
  # loaded into the next drawing. Threading `authEnabled` (also from
  # `AuthContext`, already exposed) down to the three gates (load in
  # useEditorSceneLoader, save in useEditorPersistence, #addLibrary= import
  # in useLibraryImportFromUrl) and OR-ing it into each `user` check turns
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
        $'    refs: persistenceRefs,\n    user,' \
        $'    refs: persistenceRefs,\n    user,\n    authEnabled,'

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
        'if (!id || !userIdKey) return;' \
        'if (!id || (!userIdKey && authEnabled !== false)) return;' \
      --replace-fail \
        '}, [id, userIdKey, location.hash,' \
        '}, [authEnabled, id, userIdKey, location.hash,'

    substituteInPlace src/pages/editor/useEditorPersistence.ts \
      --replace-fail \
        $'  refs: PersistenceRefs;\n  user: unknown;' \
        $'  refs: PersistenceRefs;\n  user: unknown;\n  authEnabled: boolean | null;' \
      --replace-fail \
        $'  refs,\n  user,\n  normalizeImageElementStatus,' \
        $'  refs,\n  user,\n  authEnabled,\n  normalizeImageElementStatus,' \
      --replace-fail \
        'if (!user || sessionGeneration !== getAuthSessionGeneration()) return;' \
        'if ((!user && authEnabled !== false) || sessionGeneration !== getAuthSessionGeneration()) return;'
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
