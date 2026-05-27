{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  rev = "1f50f0ecad48bac7b41a673af4873e2a3885a7f9";
  baseUrl = "https://raw.githubusercontent.com/google/fonts/${rev}/ofl/goldman";
in
stdenvNoCC.mkDerivation {
  pname = "goldman";
  version = "unstable-2025-05-27";

  srcs = [
    (fetchurl {
      url = "${baseUrl}/Goldman-Regular.ttf";
      hash = "sha256-dH1OtUf/yhscTOtJ048Eos2HZ9XYZCW3EpBFarjrKAo=";
    })
    (fetchurl {
      url = "${baseUrl}/Goldman-Bold.ttf";
      hash = "sha256-PYdbwC153/hjaa2ltMTYwbexhLxwoyK2UapcOWk2MeM=";
    })
  ];

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm644 $srcs -t $out/share/fonts/truetype
    runHook postInstall
  '';

  meta = {
    description = "Goldman – a decorative display font by Güneş Özbek";
    homepage = "https://fonts.google.com/specimen/Goldman";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
}
