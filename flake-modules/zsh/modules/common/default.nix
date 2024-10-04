# A set of settings that are common for both modules
{ pkgs, config, ... }:
let
  inherit (pkgs.lib)
    getExe
    concatMapStringsSep
    concatStringsSep
    pipe
    ;
  inherit (config.my-colortheme) semantic;
in
rec {
  # Shell aliases
  shellAliases = {
    e = "$EDITOR";
    man = "man -P 'nvim +Man!'";
    nvim = "$EDITOR";
    vim = "$EDITOR";
    ls = "${getExe pkgs.eza} -h --group-directories-first --icons=auto";
    l = "ls";
    ll = "ls -l";
    la = "ls -al";
    ka = "${getExe pkgs.killall}";
    mkd = "mkdir -pv";
    ga = "${getExe pkgs.git} add";
    gau = "ga -u";
    grep = "grep --color=auto";
    mv = "mv -v";
    rm = "${pkgs.coreutils}/bin/rm -id";
    vidir = "${pkgs.moreutils}/bin/vidir --verbose";
    ccopy = concatStringsSep " " [
      "${getExe pkgs.perl} -p -e 'chomp if eof'"
      "|"
      (if pkgs.stdenv.isDarwin then "pbcopy" else "${pkgs.wl-clipboard}/bin/wl-copy")
    ];
    syu = "systemctl --user";
    ju = "journalctl --user";
    cde = "cd /etc/nixos";
    lg = "${getExe pkgs.lazygit}";
    # Colorize IP output
    ip = "ip -c";
    # Neat display of all relevant things in lsblk
    lsblk = "lsblk --topology --fs -o NAME,SIZE,TYPE,LABEL,UUID,FSAVAIL,FSUSE%,MOUNTPOINTS";
    # Quick nix repl with stable nixpkgs imported
    nrn = "nix repl -f flake:ns";
    nrs = "nix repl -f flake:ns";
    nru = "nix repl -f flake:nu"; # Unstable
    # Load flake into repl. Try $PRJ_ROOT first, if not found -- fall back to PWD
    nrlf = ''nix repl --expr "builtins.getFlake \"''${PRJ_ROOT:-$PWD}\""'';
    poweroff = "confirm poweroff";
    reboot = "confirm reboot";
  };
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
    ];
  additionalOptions =
    [
      "INTERACTIVE_COMMENTS" # Bash-style comments in interactive shell
    ]
    ++ [
      "BANG_HIST" # Log !!-like commands
      "INC_APPEND_HISTORY" # Write to the history file immediately, not when the shell exits.
      "HIST_VERIFY" # Don't execute immediately upon history expansion.
      "HIST_FCNTL_LOCK" # enable fcntl syscall for saving history
    ];
  initExtra = concatStringsSep "\n" [
    # Enable all options
    (concatMapStringsSep "\n" (opt: "setopt ${opt}") additionalOptions)
    # Source default fzf bindings
    "source ${pkgs.fzf}/share/fzf/key-bindings.zsh"
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
    # Escape URLs when pasting
    ''
      # Automatically escape urls when pasting
      autoload -Uz url-quote-magic
      zle -N self-insert url-quote-magic
      autoload -Uz bracketed-paste-magic
      zle -N bracketed-paste bracketed-paste-magic
    ''

    (pipe (import ./functions.nix { inherit pkgs; }) [
      (builtins.mapAttrs (name: value: "${name}(){${value.text}}")) # Turn into zsh function
      builtins.attrValues
      (concatStringsSep "\n")
    ])

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
    # Using zsh highlighting with long paths (like nix store) can be slow. This fixes it.
    ''
      # found https://gist.github.com/magicdude4eva/2d4748f8ef3e6bf7b1591964c201c1ab
      pasteinit() {
        OLD_SELF_INSERT=''${''${(s.:.)widgets[self-insert]}[2,3]}
        zle -N self-insert url-quote-magic # I wonder if you'd need `.url-quote-magic`?
      }

      pastefinish() {
        zle -N self-insert $OLD_SELF_INSERT
      }
      zstyle :bracketed-paste-magic paste-init pasteinit
      zstyle :bracketed-paste-magic paste-finish pastefinish
    ''
    ''
      # Source
      # https://github.com/zsh-users/zsh-syntax-highlighting/issues/359
      typeset -gA ZSH_HIGHLIGHT_STYLES
      ZSH_HIGHLIGHT_STYLES[comment]='fg=${semantic.comment.number}'
    ''
    # Allows searching for completion
    # ''
    #   zstyle ':completion:*:*:*:default' menu yes select search
    # ''
    # fzf-tab config
    (
      let
        previewers = rec {
          dir = "${getExe pkgs.eza} -1 --color=always $realpath";
          file = "${getExe pkgs.bat} --plain --color=always $realpath";
          dispatcher =
            # bash
            ''
              if [[ -d $realpath ]]; then
                ${dir}
              elif [[ -f $realpath ]]; then
                ${file}
              fi
            '';
        };
      in
      ''
        # disable sort when completing `git checkout`
        zstyle ':completion:*:git-checkout:*' sort false
        # set descriptions format to enable group support
        zstyle ':completion:*:descriptions' format '[%d]'
        # set list-colors to enable filename colorizing
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
        # preview directory's content with eza when completing cd
        zstyle ':fzf-tab:complete:cd:*' fzf-preview '${previewers.dir}'

        # preview file's content with bat when completing vim
        zstyle ':fzf-tab:complete:$EDITOR:*' fzf-preview '${previewers.dispatcher}'
        # Quickly accept suggestion
        zstyle ':fzf-tab:*' fzf-bindings 'space:accept'
        zstyle ':fzf-tab:*' accept-line enter
        # Kill processes
        zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
        zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview \
          '[[ $group == "[process ID]" ]] && ps --pid=$word -o cmd -w -w'
        zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-flags --preview-window=down:3:wrap

        # Systemctl
        zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'
        # Space to continue completions
        zstyle ':fzf-tab:*' continuous-trigger space

        # Case-insensitive completion
        zstyle ':completion:*' matcher-list \
          'm:{[:lower:]}={[:upper:]}' \
          '+r:|[._-]=* r:|=*' \
          '+l:|=*'
      ''
    )
  ];
  completionInit = ''
    autoload -U compinit && compinit -C -i
  '';
  myPlugins = {
    baseDir = ./myPlugins;
    list = [
      "vim-edit"
      "cd-stack"
      "bookmarks"
      "cursor_mode"
    ];
  };
  packagePlugins = [
    rec {
      name = "fzf-tab";
      src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
      file = "${name}.plugin.zsh";
    }
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
