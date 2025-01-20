# Configures shell for root user
{ pkgs, ... }:
{
  users.users.root.shell = pkgs.zsh;
  environment.systemPackages = [ ];
}
