{
  fetchFromGitHub,
  stdenv,
}:
stdenv.mkDerivation {
  pname = "dashboard-icons";
  version = "0-unstable-2026-11-16";

  src = fetchFromGitHub {
    owner = "homarr-labs";
    repo = "dashboard-icons";
    rev = "d4b500dc40a8e1043b1581cabb7208892cf35472";
    hash = "sha256-1WSSs4VbBFbHGOXPfTcARzvLYYVrFJN3Ec3pxk2I2IA=";
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
