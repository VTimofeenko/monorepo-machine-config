{
  fetchFromGitHub,
  stdenv,
}:
stdenv.mkDerivation {
  pname = "dashboard-icons";
  version = "0-unstable-2026-11-06";

  src = fetchFromGitHub {
    owner = "homarr-labs";
    repo = "dashboard-icons";
    rev = "59f1e9a4108f4f510f41e9588f078631de1e1405";
    hash = "sha256-4AOGNLbZbUbt+AY5GilnsTt8H3EUubPPNATSNz5dT1c=";
  };

  dontBuild = true;

  installPhase = ''
    dirs=( png svg )

    for dir in "''${dirs[@]}"; do
      mkdir -p "$out/$dir"
      cp -R "$src/$dir/"/* "$out/$dir"
    done
  '';

  meta = {
    description = "A set of dashboard icons";
    homepage = "https://github.com/homarr-labs/dashboard-icons";
  };
}
