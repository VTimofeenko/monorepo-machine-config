{
  description = "Development flake";

  inputs = {
    parent.url = ./..;
    # This will reduce the number of `nixpkgs` instances floating around
    # Requires `nix flake update --inputs-from ..`
    # Note that `nixpkgs.follows = "nixpkgs"` will not work, it will cause a loop
    thisNixpkgs.url = "nixpkgs";
    nixpkgs.follows = "thisNixpkgs";

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stub.url = "github:VTimofeenko/stub-flake";

    my-flake-modules = {
      url = "github:VTimofeenko/flake-modules";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        nixpkgs-unstable.follows = "nixpkgs-unstable";
        nixpkgs-stable.follows = "nixpkgs-stable";
        flake-parts.follows = "flake-parts";
        devshell.follows = "devshell";
        deploy-rs.follows = "stub"; # Unstub if needed
      };
    };
  };

  outputs =
    inputs@{ ... }:
    let
      # This bit of code allows reusing the parent's inputs
      parentInputs = inputs.parent.inputs;
    in
    parentInputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { ... }: # Here be flake-parts-lib if I ever need it
      {
        imports = [
          inputs.devshell.flakeModule
          inputs.treefmt-nix.flakeModule
        ];
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        perSystem =
          {
            self',
            pkgs,
            config,
            ...
          }:
          {
            devshells = import ./devshell.nix {
              inherit config self';
              inherit (pkgs) lib;
            };

            treefmt = {
              projectRootFile = "flake.nix";
              # When run in CI, will have `treefmt` check the whole repo
              projectRoot = inputs.parent;
              programs = {
                nixfmt.enable = true;
                statix.enable = true;
                deadnix.enable = true;
              };
            };

          };
        flake = { };
      }
    );
}
