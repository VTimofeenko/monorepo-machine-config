# A set of settings that are common for both modules
{
  pkgs,
  self,
  ...
}:
let
  inherit (pkgs.lib)
    getExe
    concatMapStringsSep
    concatStringsSep
    ;
in
rec {
  # InteractiveShellInit?
  # List of shell-only packages
  packages =
    builtins.attrValues {
      inherit (pkgs)
        fzf # fuzzy finder. Installed for completions.
        bat # cat with wings!
        jq # parsing some JSON
        direnv # controls environments in projects
        curl # does not need introduction
        wget # neither does this
        fd # find replacement with saner syntax
        inetutils # a couple of utilities to be kept offline
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
    }
    ++ [
      (pkgs.writeShellScriptBin "deploy-local" ''
        set -euo pipefail

        if [[ $(grep -s ^NAME= /etc/os-release | sed 's/^.*=//') == "NixOS" ]]; then
          sudo nixos-rebuild switch --flake ''${DOTFILES_REPO_LOCATION}
        else # Not a NixOS machine
          home-manager switch --flake ''${DOTFILES_REPO_LOCATION}
        fi
      '')
      (import ./packages/confirm.nix { inherit (pkgs) writeShellApplication; })
      (pkgs.writeShellScriptBin "vim-minimal" ''
        ${pkgs.lib.getExe' self.packages.${pkgs.stdenv.system}.vim-minimal "nvim"} "$@"
      '')
    ];
  additionalOptions = [
    "INTERACTIVE_COMMENTS" # Bash-style comments in interactive shell
  ];
  initExtra = concatStringsSep "\n" [
    # Enable all options
    (concatMapStringsSep "\n" (opt: "setopt ${opt}") additionalOptions)
    ''
      # Word Navigation shortcuts
      bindkey "^A" vi-beginning-of-line
      bindkey "^E" vi-end-of-line
      bindkey "^F" end-of-line

      # ctrl+arrow for word jupming
      bindkey "^[[1;5C" forward-word
      bindkey "^[[1;5D" backward-word

      # alt+f forward a word
      bindkey "^[f" forward-word
      # alt+b back a word
      bindkey "^[b" backward-word
      # working backspace
      bindkey -v '^?' backward-delete-char
    ''
    # Vim keys in tab complete menu
    ''
      zmodload zsh/complist
      bindkey -M menuselect 'h' vi-backward-char
      bindkey -M menuselect 'k' vi-up-line-or-history
      bindkey -M menuselect 'l' vi-forward-char
      bindkey -M menuselect 'j' vi-down-line-or-history
      bindkey -M menuselect '^ ' accept-line

      # Add entry by "+" but do not exit menuselect
      bindkey -M menuselect "+" accept-and-menu-complete
    ''
    # automatically open files with certain extensions in EDITOR
    (concatMapStringsSep "\n" (ext: "alias -s ${ext}=$EDITOR") [
      "nix"
      "ncl"
      "md"
      "yml"
      "yaml"
      "sql"
      "lua"
      "toml"
      "json"
      "rs"
      "py"
    ])

    # Debug stuff
    ''
      _debug_show_completions(){
        for command completion in ''${(kv)_comps:#-*(-|-,*)}
        do
          printf "%-32s %s\n" $command $completion
        done | sort | less
      }
    ''
  ];
  variables = {
    EDITOR = "nvim";
    FZF_CTRL_T_COMMAND = "${getExe pkgs.fd} .";
    FZF_ALT_C_COMMAND = "${getExe pkgs.fd} -t d .";
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
    # May be obsoleted by https://github.com/nix-community/home-manager/pull/4713
    DOTFILES_REPO_LOCATION = "$HOME/code/literate-machine-config";
  };
}
