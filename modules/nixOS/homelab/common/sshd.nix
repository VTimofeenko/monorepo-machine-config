# sshd configuration
{ lib, ... }:
let
  inherit (lib.homelab) getSettings;
in
{
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
    openFirewall = false; # WARN: important
  };
  users.users.root.openssh.authorizedKeys.keys = getSettings.SSHKeys;
  networking.firewall.interfaces.mgmt.allowedTCPPorts = [ 22 ];
}
