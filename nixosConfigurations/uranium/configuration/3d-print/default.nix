{ pkgs, pkgs-unstable, ... }:
let
  openscadPkg = pkgs.openscad-unstable;

  scad-render = pkgs.callPackage ./scad-render { openscad = openscadPkg; };
  bgcode = pkgs.callPackage ./bgcode-renderer { };
in
{
  environment.systemPackages = [
    openscadPkg
    pkgs.prusa-slicer
    pkgs-unstable.orca-slicer
    scad-render
    bgcode
  ];
  fonts = {
    packages =
      {
        inherit (pkgs) roboto twitter-color-emoji font-awesome;
        inherit (pkgs.nerd-fonts) jetbrains-mono;
        inherit (pkgs) goldman good-timings russo-one; # My fonts
      }
      |> builtins.attrValues;
    fontconfig = {
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font" ];
        sansSerif = [ "Roboto" ];
        serif = [ "Roboto" ];
        emoji = [ "Twitter Color Emoji" ];
      };
    };
  };
}
