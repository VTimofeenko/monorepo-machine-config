{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  rev = "1f50f0ecad48bac7b41a673af4873e2a3885a7f9";
in
stdenvNoCC.mkDerivation {
  pname = "russo-one";
  version = "unstable-2025-05-27";

  src = fetchurl {
    url = "https://raw.githubusercontent.com/google/fonts/${rev}/ofl/russoone/RussoOne-Regular.ttf";
    hash = "sha256-vAq8xmC9i3rTAA7LKJiifFiimlD37IFlL6EudRSNCd8=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm644 $src $out/share/fonts/truetype/RussoOne-Regular.ttf
    runHook postInstall
  '';

  meta = {
    description = "Russo One – a bold sans-serif font by Jovanny Lemonad";
    homepage = "https://fonts.google.com/specimen/Russo+One";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
}
