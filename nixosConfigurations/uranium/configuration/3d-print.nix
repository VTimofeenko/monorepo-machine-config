{ pkgs, ...}:
{
  environment.systemPackages = [
    pkgs.openscad
    pkgs.prusa-slicer
  ];
}
