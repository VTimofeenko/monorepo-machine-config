{ pkgs, ... }:
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
      # Wrapper around `nixos-option` that allows printing per-host options.
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
              pkgs.nixos-option
              (pkgs.callPackage ../packages/nopt-parser/package.nix { })
            ];
          }
        )
      )
      # Bubblewrap wrapper around Gemini cli that fetches latest version
      (
        pkgs.writeTextFile rec {
          name = "bwrap-gemini";
          text = /* bash */ ''
            #!/usr/bin/env -S nix shell github:NixOS/nixpkgs?ref=nixos-unstable#gemini-cli nu#bubblewrap --command bash
            if [ "$(pwd)" = "$HOME" ]; then
                echo "Error: Running from \$HOME would expose your files via the /work bind."
                echo "Please cd into a specific project directory before running."
                exit 1
            fi

            bwrap \
              --ro-bind /usr /usr \
              --ro-bind /run /run \
              --ro-bind /nix /nix \
              --ro-bind /etc /etc \
              --proc /proc \
              --dev /dev \
              --tmpfs /tmp \
              --unshare-all \
              --share-net \
              --die-with-parent \
              --new-session \
              --bind "$HOME/.gemini" /homeless-shelter/.gemini \
              --setenv HOME /homeless-shelter \
              --bind "$(pwd)" /work \
              --chdir /work \
              gemini
          '';
          executable = true;
          destination = "/bin/${name}";
        }
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
