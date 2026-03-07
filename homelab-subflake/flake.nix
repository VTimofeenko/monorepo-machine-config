{
  description = "A very basic flake";

  inputs = {
    base.url = "..";
    nixpkgs.follows = "base/nixpkgs";
    flake-parts.follows = "base/flake-parts";
    data-flake.url = "path:///home/spacecadet/code/private-data-flake";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    impermanence.url = "github:nix-community/impermanence";

    private-modules = {
      url = "path:///home/spacecadet/code/private-modules";
      inputs.data-flake.follows = "data-flake";
    };
  };

  outputs =
    inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { withSystem, ... }:
      let
        inherit (inputs.base.lib) flakeModuleLoader;
        inherit (inputs.nixpkgs) lib;
      in
      {
        imports = (
          flakeModuleLoader {
            dir = ./flake-modules;
            inherit self withSystem lib;
            debug = true;
          }
        );
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        flake = {
          nixosConfigurations =
            {
              sodium = {
                role = "server";
                extraModules = [ ];
              };
            }
            |> lib.mapAttrs (
              n: v:
              self.lib.mkHost {
                hostName = n;
                inherit (v) role extraModules;
                debug = true;
              }
            );

          serviceModules = self.lib.discoverModules ./services "service";

          traitModules = self.lib.discoverModules ./traits "trait";

          lib = import ./flake-lib.nix { inherit lib self; };
        };
      }
    );
}
