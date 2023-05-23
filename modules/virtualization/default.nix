# [[file:../../new_project.org::*Virtualization][Virtualization:1]]
{ pkgs, ... }: {
  virtualisation.libvirtd.enable = true;
  environment.systemPackages = with pkgs; [ virt-manager ];
  users.users.spacecadet.extraGroups = [ "libvirtd" ];
  programs.dconf.enable = true;
}
# Virtualization:1 ends here
