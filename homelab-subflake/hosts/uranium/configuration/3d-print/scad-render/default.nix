# Agent-friendly wrapper around OpenSCAD's PNG export (see scad_render.py).
# Renders headless via EGL (no X server needed), using Mesa from the closure
# so it also works where /run/opengl-driver is absent (e.g. bwrap sandboxes).
{
  lib,
  stdenvNoCC,
  makeWrapper,
  python3,
  openscad,
  mesa,
}:
stdenvNoCC.mkDerivation {
  pname = "scad-render";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./scad_render.py
      ./test_scad_render.py
    ];
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ python3 ];
  nativeCheckInputs = [ python3 ];

  doCheck = true;
  checkPhase = ''
    runHook preCheck
    python3 -m unittest -v test_scad_render
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 scad_render.py $out/bin/scad-render
    wrapProgram $out/bin/scad-render \
      --prefix PATH : ${lib.makeBinPath [ openscad ]} \
      --set-default __EGL_VENDOR_LIBRARY_DIRS ${mesa}/share/glvnd/egl_vendor.d
    runHook postInstall
  '';

  meta.mainProgram = "scad-render";
}
