{
  lib,
  config,
  pkgs,
  ...
}:
let
  srvName = "filedump";
  cfg = config.services.myFiledump;

  misc-icons = pkgs.stdenv.mkDerivation {
    name = "misc-icons";
    src = pkgs.fetchurl {
      url = "https://downloads.filestash.app/brand/logo_white.svg";
      hash = "sha256-ecpNz9I91ARQ8cepGRJthINO0BsKOgfAge3mUph+O0M=";
    };

    dontUnpack = true;
    dontBuild = true;

    installPhase = ''
      mkdir -p $out/share/icons
      cp $src $out/share/icons/filestash_logo_white.svg
    '';
  };
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
    "L+ ${cfg.dir}/misc-icons - - - - ${misc-icons}/share/icons"
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
