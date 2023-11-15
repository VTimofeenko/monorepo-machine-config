# flake module that brings in the deployment commands
# TODO: add this module to the flake outputs for reuse
{ withSystem, self }:
{ lib, config, self, inputs, ... }:
let
  /* Attrset of lists of devshell commands. Output of this module. */
  allCommands =
    pkgs:
    let
      /* Builds a derivation and then turns its main executable into a string.

      Used for devshell commands */
      commandBuildHelper = attrset: builtins.readFile (pkgs.lib.getExe (with pkgs; writeShellApplication attrset));
      /* Constructs a devShell command for a provided category. Prefixes the command and supplies category. */
      mkCommandCategory = category: { help, name, command }: {
        name = "${category}-${name}";
        inherit help command category;
      };
    in
    builtins.concatLists
      (builtins.attrValues
        (builtins.mapAttrs
          (name: value: map (mkCommandCategory name) value)
          {
            /* Deployment commands for all nixosConfigurations and for the local machine.

            The local machine deployment command is aware of running on something other than NixOS and will fall back on home-manager.
            */
            deploy =
              (map
                (machineName: {
                  help = "Deploy remote ${machineName}";
                  name = "${machineName}"; # 'deploy-' prefix will be added automatically
                  command = "nixos-rebuild --flake .#{machineName} --target-host root@${machineName}.home.arpa switch";
                })
                (builtins.attrNames self.nixosConfigurations)) ++
              [
                {
                  help = "Deploy the flake on this machine";
                  name = "local";
                  command =
                    # bash
                    ''
                      if [[ $(grep -s ^NAME= /etc/os-release | sed 's/^.*=//') == "NixOS" ]]; then
                        sudo nixos-rebuild switch --flake .
                      else # Not a NixOS machine
                       home-manager switch --flake .
                      fi'';
                }
              ];
            ci = [
              {
                help = "Build all packages";
                name = "build-all";
                # Command needs to be a string
                command = commandBuildHelper {
                  name = "build-all";
                  runtimeInputs = [ pkgs.jq ];
                  text = builtins.readFile ./assets/build-all.sh;
                };
              }
              {
                help = "Lint all the code. Managed through pre-commit.";
                name = "lint-all";
                command = ''
                  nix develop .#pre-commit --command bash -c "pre-commit run --all-files"'';
              }
              {
                help = "Run all tests";
                name = "test-all";
                command =
                  # bash
                  ''
                    echo "not implemented"
                    exit 1
                  '';
              }
            ];
            general = [ ];
          })); # // { all = builtins.concatLists (builtins.attrValues allCommands); };
in
{
  perSystem = { system, ... }: {
    # A copy of hello that was defined by this flake, not the user's flake.
    devshells.default = withSystem system ({ config, pkgs, ... }:
      {
        env = [ ];
        commands = allCommands pkgs;
        packages = [ ];
      }
    );
  };
}

