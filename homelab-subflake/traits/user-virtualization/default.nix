{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ virt-manager ];

  programs.dconf.enable = true;

  users.users.spacecadet.extraGroups = [
    "libvirtd"
    "podman"
  ];

  virtualisation = {
    libvirtd.enable = true;

    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true; # Required for containers under `podman-compose` to be able to talk to each other.
    };
  };
}
