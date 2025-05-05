{
  fetchurl,
  stdenv,
}:
stdenv.mkDerivation {
  name = "misc-icons";
  src = fetchurl {
    url = "https://downloads.filestash.app/brand/logo_white.svg";
    hash = "sha256-ecpNz9I91ARQ8cepGRJthINO0BsKOgfAge3mUph+O0M=";
  };

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/share/icons
    cp $src $out/share/icons/filestash_logo_white.svg
  '';
}
