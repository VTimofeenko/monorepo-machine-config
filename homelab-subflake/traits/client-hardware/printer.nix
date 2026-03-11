{ pkgs, ... }:
{
  services.printing = {
    enable = true;
    drivers = [ pkgs.hplipWithPlugin ];
  };

  users.users.spacecadet.extraGroups = [ "lp" ];
}
