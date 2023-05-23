# [[file:../../new_project.org::*Printer][Printer:1]]
{ pkgs, ... }: {
  services.printing = {
    enable = true;
    drivers = [ pkgs.hplipWithPlugin ];
  };
}
# Printer:1 ends here
