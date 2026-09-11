# Flake module that produces a home-manager module wrapping my zellij config.
{ ... }:
{
  programs.zellij = {
    enable = true;
    # `extraConfig` is raw KDL text - a straight passthrough of the same
    # config.kdl used by the flake app.
    extraConfig = builtins.readFile ./config.kdl;
  };
}
