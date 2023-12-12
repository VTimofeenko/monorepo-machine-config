# sshd configuration
{ config, ... }:
let
  inherit (config) my-data;
in
{
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
    openFirewall = false; # WARN: important
  };
  users.users.root.openssh.authorizedKeys.keys = my-data.settings.SSHKeys;
  # networking.firewall.allowedTCPPorts = [ 22 ]; # TODO: allow only on management network
}
