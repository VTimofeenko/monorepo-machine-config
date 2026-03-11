{ pkgs, ... }:
{
  users.users.spacecadet = {
    isNormalUser = true;
    shell = pkgs.zsh;
  };
}
