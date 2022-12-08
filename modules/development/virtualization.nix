{ pkgs, ... }:

{
  virtualisation.libvirtd.enable = true;
  programs.dconf.enable = true;
  environment.systemPackages = with pkgs; [ virt-manager ];
  users.users.spacecadet.extraGroups = [ "libvirtd" ];
}
