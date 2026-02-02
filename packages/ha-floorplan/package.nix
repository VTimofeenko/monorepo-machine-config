/*
  Nix package that contains `ha-floorplan` for Home Assistant.

  Docs: https://experiencelovelace.github.io/ha-floorplan/
*/
{ buildNpmPackage, fetchFromGitHub }:

buildNpmPackage rec {
  pname = "ha-floorplan";
  version = "1.1.4";

  src = fetchFromGitHub {
    owner = "ExperienceLovelace";
    repo = "ha-floorplan";
    rev = "v${version}";
    sha256 = "sha256-qgRLdKpfb7ougengsN6fK7IrzZYBDvdgDSAARno37mM=";
  };

  npmDepsHash = "sha256-WUgoN9pS718+PhTuYVtShQB6VUyBkdWNlswJsImJ6XU=";

  installPhase = ''
    mkdir -p $out/ha-floorplan
    if [ -f dist/floorplan.js ]; then
      cp dist/floorplan.js $out/ha-floorplan/
    elif [ -f floorplan.js ]; then
      cp floorplan.js $out/ha-floorplan/
    else
      echo "Could not find floorplan.js in $(ls)"
      exit 1
    fi
  '';
}
