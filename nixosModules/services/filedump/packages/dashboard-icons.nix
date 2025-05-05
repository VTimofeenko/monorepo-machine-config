{
  fetchFromGitHub,
  stdenv,
}:
stdenv.mkDerivation {
  name = "Dashboard-icons";

  src = fetchFromGitHub {
    owner = "walkxcode";
    repo = "Dashboard-Icons";
    rev = "3249c1d5a15bfd81b401a73d97443c3edcf31d59";
    hash = "sha256-ATACFCJln2UJrUpibYrQXSbXuCIwuYdnbjKMvNN71no=";
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
    homepage = "https://github.com/walkxcode/Dashboard-Icons";
  };
}
