# [[file:../../new_project.org::*Scanner][Scanner:1]]
{ pkgs, ... }: {
  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.hplipWithPlugin ];
  };
  services.avahi = {
    enable = true;
    nssmdns = true;
  };
  users.users.spacecadet.extraGroups = [ "scanner" ];
}
# Scanner:1 ends here
