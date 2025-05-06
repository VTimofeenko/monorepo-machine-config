/**
  Flake-module for python development tools.

  Provides:
  - A linter
  - A formatter
*/
{ withSystem, self, ... }:
{
  perSystem =
    { system, ... }:
    {
      packages = withSystem system (
        { pkgs, ... }:
        let
          ruffConfig = pkgs.callPackage ./ruff-config.nix { };
        in
        {
          python-formatter = pkgs.writeShellApplication {
            name = "python-formatter";

            runtimeInputs = [ pkgs.ruff ];

            text = ''
              ruff check\
                  --config ${ruffConfig} \
                  --fix \
                  --preview \
                  --quiet \
                  --exit-zero `# it can keep complaining to stderr, but should not fail. EFM uses zero exit code to apply the change` \
                  "$@"
            '';
          };

          python-linter = pkgs.writeShellApplication {
            name = "python-linter";

            runtimeInputs = [ pkgs.ruff ];

            text = ''
              ruff check\
                    --config ${ruffConfig} \
                    --quiet \
                    --preview \
                    "$@"
            '';
          };
        }
      );

      checks = withSystem system (import ./check.nix { inherit self; });
    };
}
