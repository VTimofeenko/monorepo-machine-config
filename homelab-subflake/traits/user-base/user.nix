{ pkgs, ... }:
{
  users.users.spacecadet = {
    isNormalUser = true;
    shell = pkgs.zsh; # NOTE: shell is configured further in a different trait
  };
}
