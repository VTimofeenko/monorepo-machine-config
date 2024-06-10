# Config for my NixOS installer
{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (config) my-data;
in
{
  # Force start SSH
  systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];
  users.users.root.openssh.authorizedKeys.keys = my-data.settings.SSHKeys;
  services.openiscsi = {
    name = "neutronium";
    enable = true;
  };
  environment.systemPackages = [
    pkgs.openiscsi
    pkgs.libiscsi
  ];

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = "experimental-features = nix-command flakes";
  };
}
