{ pkgs, ... }:

{
  hardware.sane.enable = true;
  hardware.sane.extraBackends = [ pkgs.hplipWithPlugin ];
  services.avahi.enable = true;
  services.avahi.nssmdns = true;
  users.users.spacecadet.extraGroups = [ "scanner" ];
}
