# Home-manager module that configures custom swayimg module
{
  nixpkgs-unstable,
  pkgs,
  ...
}:
{
  imports = [
    ./impl.nix
  ];

  programs.swayimg = {
    enable = true;
    # FIXME: [24.11]
    package = nixpkgs-unstable.legacyPackages.${pkgs.system}.swayimg;
    settings = {
      # Disable showing image metadata (needs >2.2 in nixpkgs-stable) [24.11]
      info.show = "no";
      "keys.viewer" = {
        n = "next_file";
        p = "prev_file";
      };
      "keys.gallery" = {
        "h" = "step_left";
        "j" = "step_down";
        "k" = "step_up";
        "l" = "step_right";
      };
    };
  };
}
