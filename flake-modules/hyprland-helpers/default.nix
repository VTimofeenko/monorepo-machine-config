# Flake module for the homegrown Hyprland helpers and their module
# Doc is here: https://crane.dev
{
  withSystem, # Flake-parts helper
  lib, # To use the common lib
  self,
  ...
}:
{
  perSystem =
    { system, ... }:
    let
      craneLib = self.inputs.crane.lib.${system}; # NOTE: not inputs' since it seems to strip non-standard outputs.
    in
    {
      packages = withSystem system (
        {
          pkgs,
          # , inputs'
          ...
        }:
        let
          version = "0.1.0";
          # Taken from crane quickstart, slightly modified for flake-parts
          src = craneLib.cleanCargoSource (craneLib.path ./src);
          # Common arguments can be set here to avoid repeating them later
          commonArgs = rec {
            inherit src version;
            strictDeps = true;
            name = "hyprland-helpers";
            pname = name;
            meta.mainProgram = ""; # There is no explicit main package here
            buildInputs = lib.optionals pkgs.stdenv.isDarwin [
              # Additional darwin specific inputs can be set here
              pkgs.libiconv
            ];

            # Additional environment variables can be set directly
            # MY_CUSTOM_VAR = "some value";
          };
          # craneLibLLvmTools = craneLib.overrideToolchain
          #   (inputs'.fenix.packages.complete.withComponents [
          #     "cargo"
          #     "llvm-tools"
          #     "rustc"
          #   ]);

          # Build *just* the cargo dependencies, so we can reuse
          # all of that work (e.g. via cachix) when running in CI
          cargoArtifacts = craneLib.buildDepsOnly commonArgs;

          # Build the actual crate itself, reusing the dependency
          # artifacts from above.
          hyprland-helpers = craneLib.buildPackage (commonArgs // { inherit cargoArtifacts; });

          workspaceMembers = (builtins.fromTOML (builtins.readFile ./src/Cargo.toml)).workspace.members;
          # Constructs an attrset with packages taken from workspace members. This is used to expose them in the flake output
          workspaceNixPackages = builtins.listToAttrs (
            map
              (name: {
                inherit name;
                value = craneLib.buildPackage {
                  inherit src cargoArtifacts version;
                  pname = name;
                  cargoExtraArgs = "-p ${name}";
                  meta.mainProgram = name;
                };
              })
              workspaceMembers
          );
        in
        {
          # Actual packages output
          inherit hyprland-helpers;
          # Not sure if needed
          # hyprland-helpers-llm-coverage = craneLibLLvmTools.cargoLlvmCov (commonArgs // {
          #   inherit cargoArtifacts;
          # });
        }
        // workspaceNixPackages
      );

      devShells = withSystem system (_: { rust = craneLib.devShell { }; });

      # Pre-commit hooks
      pre-commit.settings = {
        # TODO: reenable, flaky

        # hooks.clippy.enable = true;
        # hooks.rustfmt.enable = true;
        settings.rust.cargoManifestPath = "./flake-modules/hyprland-helpers/src/Cargo.toml";
      };
    };
  flake = {
    homeManagerModules = {
      hyprland-helpers = import ./homeManagerModules self;
      hyprland-language-switch-notifier = import ./homeManagerModules/hyprland-language-switch-notifier.nix self;
      hyprland-mode-switch-notifier = import ./homeManagerModules/hyprland-mode-switch-notifier.nix self;
      hyprland-workspace-switch-notifier = import ./homeManagerModules/hyprland-workspace-notifier.nix self;
    };
  };
}
