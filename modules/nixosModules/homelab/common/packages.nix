# Common packages to be installed on all hosts
{ pkgs, ... }:
{
  environment.systemPackages = builtins.attrValues { inherit (pkgs) git; };
}
