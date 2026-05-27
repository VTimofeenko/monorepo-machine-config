{
  lib,
  stdenvNoCC,
  fetchzip,
}:

stdenvNoCC.mkDerivation {
  pname = "good-timings";
  version = "unstable-2019-05-25";

  src = fetchzip {
    url = "https://dl.dafont.com/dl/?f=good_timing";
    extension = "zip";
    stripRoot = false;
    hash = "sha256-xrUy5WZ9ixGhxPgWGsG7H8KNP+fR0ZK/Vv1QigN5pIY=";
  };

  installPhase = ''
    runHook preInstall
    install -Dm644 "good timing bd.otf" $out/share/fonts/opentype/good-timing-bd.otf
    runHook postInstall
  '';

  meta = {
    description = "Good Timings – a decorative display font by Typodermic Fonts";
    homepage = "https://www.dafont.com/good-timing.font";
    # Free for personal use; commercial use requires a license from Typodermic
    license = lib.licenses.unfreeRedistributable;
    platforms = lib.platforms.all;
  };
}
