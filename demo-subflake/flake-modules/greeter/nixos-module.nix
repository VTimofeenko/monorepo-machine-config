{ lib, pkgs, config, ... }:
let
  cfg = config.programs.greeter;
in
{
  options.programs.greeter.enable = lib.mkEnableOption "greeter";
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.greeter ];
  };
}
