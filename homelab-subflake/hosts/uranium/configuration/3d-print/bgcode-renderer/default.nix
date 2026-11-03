# Pure-Python Prusa .bgcode inspector; stdlib only.
{
  lib,
  stdenvNoCC,
  python3,
}:
stdenvNoCC.mkDerivation {
  pname = "bgcode";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./bgcode.py
      ./test_bgcode.py
      ./shape.bgcode
    ];
  };

  buildInputs = [ python3 ];
  nativeCheckInputs = [ python3 ];

  doCheck = true;
  checkPhase = ''
    runHook preCheck
    python3 -m unittest -v test_bgcode
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 bgcode.py $out/bin/bgcode
    runHook postInstall
  '';

  meta.mainProgram = "bgcode";
}
