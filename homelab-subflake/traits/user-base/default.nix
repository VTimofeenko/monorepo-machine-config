{ inputs, pkgs-unstable, ... }:
{
  imports = [
    ./user.nix
    inputs.home-manager.nixosModules.default
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs pkgs-unstable; };
  };

  home-manager.users.spacecadet.imports = [
    ./general-home-manager.nix
    inputs.base.homeManagerModules.my-theme
  ];
}
