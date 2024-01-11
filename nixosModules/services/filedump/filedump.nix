/* NixOS module to configure filedump */
{ lib, config, pkgs, ... }:
let
  cfg = config.services.myFiledump;
in
{
  options.services.myFiledump.dir = lib.mkOption { type = lib.types.path; default = "/var/lib/filedump"; };
  config.systemd.tmpfiles.rules = [
    "d ${cfg.dir} 0755 root root"
    "L ${cfg.dir}/dashboard-icons - - - - ${pkgs.dashboard-icons}"
  ];
}
