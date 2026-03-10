{ inputs, ... }:
{
  imports = [
    inputs.xremap-flake.nixosModules.default
    ./shortcuts.nix
  ];

  services.xremap = {
    enable = true;
    withWlroots = true;
    userName = "spacecadet";
    serviceMode = "user";
    watch = true;
  };
}
