{ fetchFromGitHub
, stdenv
, src' ? null
}:
stdenv.mkDerivation {
  name = "Dashboard-icons";

  src =
    if builtins.isNull src' then
      fetchFromGitHub
        {
          owner = "walkxcode";
          repo = "Dashboard-Icons";
          rev = "3249c1d5a15bfd81b401a73d97443c3edcf31d59";
          hash = "sha256-ATACFCJln2UJrUpibYrQXSbXuCIwuYdnbjKMvNN71no=";
        }
    else
      src';

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
