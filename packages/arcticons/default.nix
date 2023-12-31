{ pkgs, src, ... }:
# let
# TODO:
#   my-mappings-patch = ./my-mappings.patch;
# in
pkgs.stdenv.mkDerivation {
  name = "Arcticons-icon-pack";
  inherit src;
  dontUnpack = true;
  buildInputs = [ pkgs.inkscape pkgs.bash ];
  buildPhase = ''
    cd $src/freedesktop-theme
    bash generate-all.sh
  '';
  installPhase = ''
    mkdir -p $out/share/icons
    cp -R arcticons-dark $out/share/icons
    cp -R arcticons-light $out/share/icons
  '';
}
