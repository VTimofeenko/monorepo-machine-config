{
  lib,
  config,
  pkgs,
  ...
}:
let
  srvName = "filedump";
  cfg = config.services.myFiledump;
in
{
  options.services.myFiledump = {
    dir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/filedump";
    };
    dashboard-icons = lib.mkOption {
      type = lib.types.str;
      default = "dashboard-icons";
    };
  };

  config.systemd.tmpfiles.rules = [
    "d ${cfg.dir} 0755 root root"
    "L+ ${cfg.dir}/${cfg.dashboard-icons} - - - - ${pkgs.dashboard-icons}"
  ];

  config.services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts.${(lib.homelab.getService srvName).fqdn} = {
      forceSSL = false;
      extraConfig = ''
        proxy_buffering off;
      '';
      locations."/" = {
        extraConfig = ''
          autoindex on;
        '';
        root = config.services.myFiledump.dir;
      };
      locations."~ /${config.services.myFiledump.dashboard-icons}/png" = {
        extraConfig = ''
          error_page 404 /${config.services.myFiledump.dashboard-icons}/png/nginx.png;
        '';
        root = config.services.myFiledump.dir;
      };
    };
  };
}
