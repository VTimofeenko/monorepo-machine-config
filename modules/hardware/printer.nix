{ pkgs, ... }:
{
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.hplipWithPlugin ];
}
