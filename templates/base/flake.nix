{
  description = "Description for the project";

  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs.follows = "nixpkgs-stable";
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

      imports = [ ];

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
        };

      flake = { };
    };
}
