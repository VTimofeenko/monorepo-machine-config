{ pkgs, lib, ... }:
let
  srvName = "cyberchef";
in
{
  config.services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts.${(lib.homelab.getService srvName).fqdn} = {
      forceSSL = false;
      extraConfig = ''
        proxy_buffering off;
      '';
      locations."/" = {
        root = "${pkgs.cyberchef}/share/cyberchef";
      };
    };
  };
}
