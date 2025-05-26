/**
  Configures zsh completions.

  Features:
  - File preview when completing a file
  - Completion color scheme follows `ls` colors

  TODO: try lazy-loading the `compinit` if the performance hit is too big
  https://news.ycombinator.com/item?id=40140873
*/
{ pkgs, lib, ... }:
let
  completionStyles = [
    "zstyle ':completion:*:git-checkout:*' sort false" # Disable sort when completing `git checkout`
    "zstyle ':completion:*:descriptions' format '[%d]'" # Set descriptions format to enable group support
    "zstyle ':completion:*' list-colors \${(s.:.)LS_COLORS}" # Set list-colors to enable filename colorizing
    "zstyle ':fzf-tab:complete:cd:*' fzf-preview '${previewers.dir}'" # Preview directory's content with eza when completing `cd`
    "zstyle ':fzf-tab:complete:$EDITOR:*' fzf-preview '${previewers.dispatcher}'" # Preview file's content with bat when completing vim
    # Quickly accept suggestion
    ''
      zstyle ':fzf-tab:*' fzf-bindings 'space:accept'
      zstyle ':fzf-tab:*' accept-line enter
      zstyle ':fzf-tab:*' continuous-trigger space
    ''
    # Kill processes
    ''
      zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
      zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview \
        '[[ $group == "[process ID]" ]] && ps --pid=$word -o cmd -w -w'
      zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-flags --preview-window=down:3:wrap
    ''
    # `systemctl` completions
    "zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'"
    # Case-insensitive completion
    ''
      zstyle ':completion:*' matcher-list \
        'm:{[:lower:]}={[:upper:]}' \
        '+r:|[._-]=* r:|=*' \
        '+l:|=*'
    ''
  ];

  # Utilities that will be showing previews of completed objects
  previewers = rec {
    dir = "${lib.getExe pkgs.eza} -1 --color=always $realpath";
    file = "${lib.getExe pkgs.bat} --plain --color=always $realpath";
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

  completionInit = ''
    ZCOMPDUMP_LOCATION="$XDG_CACHE_HOME/zsh/compinit"
    mkdir -p "$(dirname "$ZCOMPDUMP_LOCATION")"
    autoload -Uz compinit

    compinit -C -i -d $ZCOMPDUMP_LOCATION

    ${completionStyles |> (lib.concatStringsSep "\n")}

    source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

  '';
in
{
  nixosModule =
    { lib, ... }:
    {
      programs.zsh.interactiveShellInit = completionInit;
      # I am assembling this by hand
      programs.zsh.enableCompletion = lib.mkForce false;

      # On advice from home manager module
      environment.pathsToLink = [ "/share/zsh" ];

    };
  homeManagerModule =
    { config, ... }:
    {
      programs.zsh = {
        enableCompletion = true;
        inherit completionInit;

        # W/A for missing completions
        # Source: https://github.com/nix-community/home-manager/issues/2562
        initContent =
          let
            profileDir = config.home.profileDirectory;
          in
          ''
            fpath+=("${profileDir}"/share/zsh/site-functions "${profileDir}"/share/zsh/$ZSH_VERSION/functions "${profileDir}"/share/zsh/vendor-completions)
          ''
          |> lib.mkOrder 550;
      };
    };
}
