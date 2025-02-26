{ pkgs, lib, ... }:
{
  environment.systemPackages =
    ''$EDITOR $(ps aux | grep nginx | head -n1 | awk '{print $NF}') "$@"''
    |> pkgs.writeShellScriptBin "view-nginx-config"
    |> lib.singleton;
}
