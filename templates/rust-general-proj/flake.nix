{
  description = "REPLACEME";  # TODO: replace

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    crane.url = "github:ipetkov/crane";
  };

  outputs =
    inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { withSystem, flake-parts-lib, ... }:
      {
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
          "x86_64-darwin"
        ];
        perSystem =
          { pkgs, ... }:
          let
            craneLib = inputs.crane.mkLib pkgs;
            pkg = craneLib.buildPackage {
              src = craneLib.cleanCargoSource ./.;
              meta.mainProgram = "REPLACEME"; # TODO: replace this
              # Most likely will need this
              nativeBuildInputs = [
                pkgs.pkg-config
                pkgs.openssl
              ];
            };
          in
          {
            checks = {
              inherit pkg;
            };
            packages.default = pkg;
            devShells.default = craneLib.devShell {
              packages = [
                pkgs.cargo-edit
                pkgs.openssl
                pkgs.pkg-config
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
