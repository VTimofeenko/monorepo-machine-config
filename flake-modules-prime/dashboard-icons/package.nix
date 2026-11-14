{
  fetchFromGitHub,
  stdenv,
}:
stdenv.mkDerivation {
  pname = "dashboard-icons";
  version = "0-unstable-2026-11-08";

  src = fetchFromGitHub {
    owner = "homarr-labs";
    repo = "dashboard-icons";
    rev = "d767d7327db7f8ebd3715b552523f61889eea41c";
    hash = "sha256-cfhHffmJ0P/AaHYpLgkzj5NfhrbI4xEeYKhLMAMvL/c=";
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
