{
  description = "Description for the project";

  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs.follows = "nixpkgs-stable";

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    pre-commit-hooks-nix = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
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
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      imports = [
        inputs.devshell.flakeModule
        inputs.pre-commit-hooks-nix.flakeModule
        inputs.treefmt-nix.flakeModule
      ] ++ (builtins.attrValues inputs.my-flake-modules.flake-modules);

      perSystem =
        {
          pkgs,
          # These inputs are unused in the template, but might be useful later
          # , config
          # , self'
          # , inputs'
          # , system
          ...
        }:
        {
          packages.default = pkgs.hello;

          devshells.default = {
            env = [
              {
                name = "HTTP_PORT";
                value = 8080;
              }
            ];
            commands = [
              {
                help = "print hello";
                name = "hello";
                command = "echo hello";
              }
            ];
            packages = [ ];
          };
        };

      flake = { };
    };
}
