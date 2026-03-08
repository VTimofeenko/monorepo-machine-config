{ pkgs, ... }:
{
  ussers.users.root.shell = pkgs.zsh;
  environment.systemPackages = [ pkgs.git ];
}
