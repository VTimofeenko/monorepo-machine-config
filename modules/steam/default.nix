{ pkgs, ... }:
{
  # From gamescope PR
  nixpkgs.config.packageOverrides = pkgs: {
    steam = pkgs.steam.override {
      extraPkgs = pkgs: with pkgs; [
        xorg.libXcursor
        xorg.libXi
        xorg.libXinerama
        xorg.libXScrnSaver
        libpng
        libpulseaudio
        libvorbis
        stdenv.cc.cc.lib
        libkrb5
        keyutils
      ];
    };
  };
  environment.systemPackages = with pkgs; [ steam gamescope ];
  # Steam needs this, otherwise there's an error Assertion Failed: Error: glXChooseVisual failed
  hardware.opengl.driSupport32Bit = true;
  environment.variables = {
    WLR_NO_HARDWARE_CURSORS = "1";
  };
}
