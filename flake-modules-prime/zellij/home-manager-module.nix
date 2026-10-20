# Flake module that produces a home-manager module wrapping my zellij config.
{ ... }:
{
  programs.zellij = {
    enable = true;
    # `extraConfig` is raw KDL text - a straight passthrough of the same
    # config used by the flake app.
    extraConfig = import ./config.nix;
  };
}
