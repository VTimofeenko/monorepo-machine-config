{
  description = "NixOS and Home Manager configurations for my machines";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    nixpkgs-lib.url = "github:NixOS/nixpkgs/nixos-unstable?dir=lib";

    nixpkgs-stable.follows = "nixpkgs";

    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs-unstable";

    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    pre-commit-hooks-nix = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
      };
    };

    # My development stuff
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs-lib";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    my-flake-modules = {
      url = "github:VTimofeenko/flake-modules";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        nixpkgs-unstable.follows = "nixpkgs-unstable";
        nixpkgs-stable.follows = "nixpkgs-stable";
        nixpkgs-lib.follows = "nixpkgs-lib";
        flake-parts.follows = "flake-parts";
        pre-commit-hooks-nix.follows = "pre-commit-hooks-nix";
        devshell.follows = "devshell";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    # Unused at the moment. TODO: use this with the local packages
    # fenix = {
    #   url = "github:nix-community/fenix";
    #   inputs.nixpkgs.follows = "nixpkgs-unstable";
    #   inputs.rust-analyzer-src.follows = "";
    # };

    # advisory-db = {
    #   url = "github:rustsec/advisory-db";
    #   flake = false;
    # };
  };
  outputs =
    inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { withSystem, ... }:
      let
        flakeModuleLoader = import ./lib/flake-module-loader.nix;
        inherit (inputs.nixpkgs-lib) lib; # A faster way to propagate lib to certain modules
      in
      {
        imports = builtins.concatLists [
          [
            inputs.devshell.flakeModule
            inputs.flake-parts.flakeModules.easyOverlay
            inputs.pre-commit-hooks-nix.flakeModule
            inputs.treefmt-nix.flakeModule
          ]
          (builtins.attrValues inputs.my-flake-modules.flake-modules)
          (flakeModuleLoader {
            dir = ./flake-modules-prime;
            inherit self withSystem lib;
            # debug = true;
          })
        ];
        systems = [
          "x86_64-linux"
          "aarch64-darwin"
          "aarch64-linux"
        ];
        perSystem =
          {
            inputs',
            pkgs,
            ...
          }:
          {
            bumpInputs = {
              # nixpkgs, nixpkgs-unstable and all inputs: `flake-bump-*` in
              # lib/devshellCmds.nix, across both flakes
              changingInputs = [
                "my-flake-modules"
              ];
            };
            # My modules config
            format-module = {
              languages = [
                "lua"
                "shell"
                "rust"
                "nickel"
              ];
              addFormattersToDevshell = true;
            };
            devshells.default =
              let
                devShellCmds = import ./lib/devshellCmds.nix { inherit pkgs; };
              in
              {
                env = [ ];
                commands = devShellCmds;
                packages = [
                  pkgs.nixos-anywhere
                  pkgs.nix-melt
                ];
              };

            checks = import ./checks { inherit self pkgs lib; };

            pre-commit = import ./.dev/pre-commit.nix { inherit inputs' lib pkgs; };
          };
        flake = {
          # flake-modules are passed through to the output of this flake
          inherit (inputs.my-flake-modules) flake-modules;
          nixosModules = {

            # Maybe later I will add dynamic imports here
            wireguard-refresh-fix = import ./modules/nixOS/wireguard-refresh-fix.nix;
          };
          templates = {
            default = {
              path = ./templates/base;
              description = "Base template for my projects";
            };
            sample-check = {
              path = ./templates/sample-check;
              description = "Template for a sample check with home-manager.";
            };
            rust-general-proj = {
              path = ./templates/rust-general-proj;
              description = "Rust project template";
            };
            python-general-proj = {
              path = ./templates/python-general-proj;
              description = "Python project template";
            };
            nix-run-uv = {
              path = ./templates/nix-run-sample;
              description = "A sample `nix run` with uv";
            };
          };

          lib = {
            inherit flakeModuleLoader;
          };
        };
      }
    );
}
