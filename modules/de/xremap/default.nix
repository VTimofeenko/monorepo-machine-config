{ xremap-flake, ... }:
{
  imports = [
    xremap-flake.nixosModules.default
    ./shortcuts.nix
  ];

  services.xremap = {
    withWlroots = true;
    userName = "spacecadet";
    serviceMode = "user";
    watch = true;
  };
}
