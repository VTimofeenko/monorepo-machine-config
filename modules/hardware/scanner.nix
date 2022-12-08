{ pkgs, ... }:

{
  hardware.sane.enable = true;
  hardware.sane.extraBackends = [ pkgs.hplipWithPlugin ];
  users.users.spacecadet.extraGroups = [ "scanner" ];
}
