# Config for my NixOS installer
{
  lib,
  pkgs,
  ...
}:
{
  # Force start SSH
  systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];
  users.users.root.openssh.authorizedKeys.keys = lib.homelab.getSettings.SSHKeys;
  services.openiscsi = {
    name = "neutronium";
    enable = true;
  };
  environment.systemPackages = [
    pkgs.openiscsi
    pkgs.libiscsi
  ];

  nix = {
    extraOptions = "experimental-features = nix-command flakes";
  };
}
