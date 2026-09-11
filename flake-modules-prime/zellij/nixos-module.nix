# Flake module that produces a NixOS module wrapping my zellij config.
# There's no upstream `programs.zellij` system-wide module (unlike tmux), so
# this just installs the package and drops the config where zellij looks for
# it system-wide (see `zellij setup --check`'s [`CONFIG DIR`] search order).
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.zellij ];
  environment.etc."zellij/config.kdl".source = ./config.kdl;
}
