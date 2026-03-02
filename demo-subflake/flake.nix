{
  description = "Demo subflake exercising lib/flake-module-loader.nix";

  inputs = {
    parent.url = ./..;
    nixpkgs.follows = "parent/nixpkgs";
    flake-parts.follows = "parent/flake-parts";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { withSystem, self, ... }:
      let
        inherit (inputs.nixpkgs) lib;
        inherit (inputs.parent.lib) flakeModuleLoader;
      in
      {
        imports = [
          inputs.flake-parts.flakeModules.easyOverlay
        ]
        ++ flakeModuleLoader {
          dir = ./flake-modules;
          inherit self withSystem lib;
          debug = true;
        };

        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
      }
    );
}
