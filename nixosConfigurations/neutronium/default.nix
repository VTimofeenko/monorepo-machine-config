# Config for my NixOS installer
{ lib, config, ... }:
let
  inherit (config) my-data;
in
{
  # Force start SSH
  systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];
  users.users.root.openssh.authorizedKeys.keys = my-data.settings.SSHKeys;
}
