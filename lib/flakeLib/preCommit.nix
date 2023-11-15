# flake module that configures pre-commit hooks environment
{ withSystem }:
let shellName = "pre-commit"; in
{
  perSystem = { system, ... }: {
    # This allows to run nix develop .#pre-commit
    # TODO: make easier to compose with default nix shell. Use lib.mkMerge?
    devShells.${shellName} = withSystem system ({ config, ... }: config.pre-commit.devShell);
    pre-commit.settings = withSystem system (_: {
      hooks = {
        nixpkgs-fmt.enable = true;
        deadnix.enable = true;
        statix.enable = true;
        stylua.enable = true;
      };
      settings = {
        statix.ignore = [ ".direnv/" ];
        statix.format = "stderr";
      };
    });
    /* Add a command to install the hooks */
    devshells.default = withSystem system ({ pkgs, ... }: {
      env = [ ];
      commands = [
        {
          help = "Install pre-commit hooks";
          name = "setup-pre-commit-install";
          command = "nix develop .#${shellName}";
          category = "setup";
        }
      ];
      # For manual checks
      packages = [
        pkgs.statix
        pkgs.deadnix
      ];
    });
  };
}
