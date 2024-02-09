{
  stdenv,
  nickel,
  lib,
}:
stdenv.mkDerivation {
  name = "theme";
  src = ./src;
  buildPhase = ''
    mkdir $out
    ${lib.getExe' nickel "nickel"} export ./theme.ncl > $out/theme.json
  '';
}
