# Runs zellij, my TTY window manager (evaluating as a tmux replacement).
{ pkgs, lib }:
let
  configFile = pkgs.writeText "zellij-config.kdl" (builtins.readFile ./config.kdl);
in
{
  type = "app";
  program = lib.getExe (
    pkgs.writeShellApplication {
      name = "zellij-wrapper";
      runtimeInputs = [ pkgs.zellij ];
      text = ''zellij --config ${configFile} "$@"'';
    }
  );
}
