{
  fetchFromGitHub,
  stdenv,
}:
stdenv.mkDerivation {
  name = "Dashboard-icons";

  src = fetchFromGitHub {
    owner = "homarr-labs";
    repo = "dashboard-icons";
    rev = "f29af6c5d79a03faab6818a8bc53c2b2064d5956";
    hash = "sha256-SY2s1vhS44YztAywsdZ4wxLdl8Yi86SDd00U6ARqe94=";
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
