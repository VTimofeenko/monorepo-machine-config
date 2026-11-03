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
}
