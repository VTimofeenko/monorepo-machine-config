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
      key.viewer = {
        n = "next_file";
        p = "prev_file";
      };
    };
  };
}
