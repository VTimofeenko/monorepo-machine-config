{ pkgs, self, ... }:
let
  settings.packages =
    (builtins.attrValues {
      inherit (pkgs)
        fzf # Fuzzy finder. Installed for completions.
        bat # Cat with wings!
        jq # Parsing some JSON
        direnv # Controls environments in projects
        curl # Does not need introduction
        wget # Neither does this
        fd # `find` replacement with saner syntax
        inetutils # A couple of utilities to be kept offline
        moreutils # a collection of additional tools
        file # Detects what kind of file is this
        ripgrep # useful grep replacement
        lsof # shows file handles
        dig # quick DNS tester
        unzip # unpacks archives
        htop # system monitoring
        eza # for completions
        spacer
        tree
        ;
    })
    ++ [
      # `deploy-local` can be called from any location to apply my config to the current machine
      (pkgs.writeShellScriptBin "deploy-local" ''
        set -euo pipefail

        if [[ $(grep -s ^NAME= /etc/os-release | sed 's/^.*=//') == "NixOS" ]]; then
          sudo nixos-rebuild switch --flake ''${DOTFILES_REPO_LOCATION}
        else # Not a NixOS machine
          home-manager switch --flake ''${DOTFILES_REPO_LOCATION}
        fi
      '')
      # `confirm` is a simple wrapper for confirming that I really want to execute a command
      (
        ''
          echo "Confirm executing $1 command on '$(hostname)' machine?"

          CMD=$1

          read -r reply

          if [[ "''${reply,,}" == "y" ]]; then
            "$@"
          else
            echo "Not running $CMD"
          fi

        ''
        |> (
          it:
          pkgs.writeShellApplication {
            name = "confirm";
            text = it;
          }
        )
      )
      # Wrapper around `nixos-option` from unstable that allows printing per-host options.
      (
        # bash
        ''
          OPTION_PATH=$1
          TGT_HOSTNAME=''${2:-$(hostname)}
          nixos-option --flake "''${DOTFILES_REPO_LOCATION}#''${TGT_HOSTNAME}" "''${OPTION_PATH}" | nopt-parser
        ''
        |> (
          it:
          pkgs.writeShellApplication {
            name = "nopt";
            text = it;
            runtimeInputs = [
              self.inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.system}.nixos-option
              (pkgs.callPackage ../packages/nopt-parser/package.nix { })
            ];
          }
        )
      )
    ];
in
{
  nixosModule = {
    environment.systemPackages = settings.packages;
  };
  homeManagerModule = {
    home = { inherit (settings) packages; };
  };
}
