{
  description = "REPLACEME"; # TODO: replace

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devshell.url = "github:numtide/devshell";
  };

  outputs =
    inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { withSystem, flake-parts-lib, ... }:
      {
        imports = [ inputs.devshell.flakeModule ];
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
          "x86_64-darwin"
        ];
        perSystem =
          { pkgs, ... }:
          {
            devshells.default = {
              packages = [
                pkgs.uv
                pkgs.python3
              ];
            };
          };
        # Remove if needed
        flake.nixosModules.default = flake-parts-lib.importApply ./nix/module.nix {
          inherit self withSystem;
        };
      }
    );
}
