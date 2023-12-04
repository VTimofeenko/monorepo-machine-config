# A set of modules to configure Doom Emacs
{ withSystem # Flake-parts helper
, lib # To use the common lib
, self
, ...
}:
{
  perSystem =
    { system
    , ...
    }:
    let
      craneLib = self.inputs.crane.lib.${system}; # NOTE: not inputs' since it seems to strip non-standard outputs.
    in
    {
      packages = withSystem system
        ({ pkgs, ... }:
          let
            src = craneLib.cleanCargoSource (craneLib.path ./emacs-notifier);
            commonArgs = rec {
              inherit src;
              version = "0.1.0";
              strictDeps = true;
              name = "emacs-notifier";
              pname = name;
              meta.mainProgram = "emacs-notifier"; # There is no explicit main package here
              buildInputs = [ pkgs.pkg-config ] ++ lib.optionals pkgs.stdenv.isDarwin [
                # Additional darwin specific inputs can be set here
                pkgs.libiconv
                pkgs.darwin.apple_sdk.frameworks.CoreFoundation
                pkgs.darwin.apple_sdk.frameworks.Cocoa
              ];
            };
            cargoArtifacts = craneLib.buildDepsOnly commonArgs;
          in
          {
            emacs-notifier = craneLib.buildPackage (commonArgs // { inherit cargoArtifacts; });
          });
    };
  flake =
    {
      # homeManagerModules.emacs = import ./hm.nix; # TODO: importApply for access to selfpkgs
    };
}
