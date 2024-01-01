# Home manager module that configures zsh
{ self }:
{ pkgs
, config
, osConfig
, lib
, ...
}:
let
  inherit (self) inputs;
  commonSettings = import ./common.nix {
    inherit pkgs;
    pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.system};
    config = osConfig;
  };

  inherit (osConfig) rawColorScheme;
  semantic = config.semanticColorScheme;

  # upstream PR in unstable https://github.com/NixOS/nixpkgs/pull/271088
  fzf-tab-override = pkgs.zsh-fzf-tab.overrideAttrs {
    env = pkgs.lib.optionalAttrs pkgs.stdenv.cc.isClang {
      NIX_CFLAGS_COMPILE = toString [
        "-Wno-error=implicit-function-declaration"
        "-Wno-error=implicit-int"
      ];
    };
  };
in
{
  home = { inherit (commonSettings) packages; };
  programs = {
    zsh = {
      enable = true;
      enableAutosuggestions = true;
      enableCompletion = true;
      # Type directory name -> cd there
      autocd = true;
      # Start in VI insert mode
      defaultKeymap = "viins";
      # Move the dotfiles to .config -- unclutter home dir
      dotDir = ".config/zsh";
      # History options
      history = {
        expireDuplicatesFirst = true;
        extended = true;
        ignoreAllDups = true;
        ignoreDups = true;
        ignorePatterns = [
          "rm *"
          "# *" # I don't care about full-line comments
        ];
        ignoreSpace = true; # Do not include lines that start with a space. On by default, but I want to make sure.
        path = "${config.xdg.dataHome}/zsh/zsh_history"; # unclutter profile
        share = true; # Share history between sessions. On by default, but I want to make sure
      };
      # initExtraBeforeCompInit # Extra commands that should be added to .zshrc before compinit.
      # W/A for missing completions
      # Source: https://github.com/nix-community/home-manager/issues/2562
      initExtraBeforeCompInit =
        let profileDir = config.home.profileDirectory; in
        ''
          fpath+=("${profileDir}"/share/zsh/site-functions "${profileDir}"/share/zsh/$ZSH_VERSION/functions "${profileDir}"/share/zsh/vendor-completions)
        '';
      # initExtraFirst # Commands that should be added to top of .zshrc.
      localVariables = commonSettings.variables
        //
        {
          BEMENU_OPTS = lib.concatStringsSep " " [
            "--tb  '#${rawColorScheme.color0}'" #Title background
            "--tf  '#${rawColorScheme.indigo}'" #Title foreground
            "--fb  '#${rawColorScheme.color0}'" #Filter background
            "--ff  '#${rawColorScheme.fg-main}'" #Filter foregroun
            "--cb  '#${rawColorScheme.color0}'" #Cursor background
            "--cf  '#${rawColorScheme.fg-main}'" #Cursor foregroun
            "--nb  '#${rawColorScheme.color0}'" #Normal background
            "--nf  '#${rawColorScheme.fg-main}'" #Normal foreground
            "--hb  '#${rawColorScheme.color0}'" #Highlighted background
            "--hf  '#${semantic.activeFrameBorder}'" #Highlighted foreground
            "--fbb '#${rawColorScheme.color0}'" #Feedback background
            "--fbf '#${rawColorScheme.fg-main}'" #Feedback foreground
            "--sb  '#${rawColorScheme.color0}'" #Selected background
            "--sf  '#${rawColorScheme.fg-main}'" #Selected foreground
            "--ab  '#${rawColorScheme.color0}'" #Alternating background color
            "--af  '#${rawColorScheme.fg-main}'" #Alternating foreground color
            "--scb '#${rawColorScheme.color0}'" #Scrollbar background
            "--scf '#${rawColorScheme.fg-main}'" #Scrollbar foreground
            "--width-factor 0.2"
          ];
        };

      plugins =
        [{ name = "fzf-tab"; src = "${fzf-tab-override}/share/fzf-tab"; }] ++
        (with commonSettings.plugins;
        map (name: { inherit name; file = "${name}.zsh"; src = baseDir; }) list);
      shellGlobalAliases = {
        G = "| rg";
      };
      syntaxHighlighting.enable = true;

      inherit (commonSettings) shellAliases completionInit;
      initExtra = commonSettings.initExtra
        # set SSH_AUTH_SOCK <=> gpg-agent is enabled in home-manager
        +
        (if config.services.gpg-agent.enable
        then
          ''
            if [[ -z "$SSH_AUTH_SOCK" ]]; then
              export SSH_AUTH_SOCK="$(${config.programs.gpg.package}/bin/gpgconf --list-dirs agent-ssh-socket)"
            fi
          ''
        else "");

    };
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      config.whitelist.prefix = [ "${config.home.homeDirectory}/code" ];
    };
    starship = {
      enable = true;
      enableBashIntegration = false;
      enableFishIntegration = false;
      enableIonIntegration = false;
      enableNushellIntegration = false;
      settings = {
        nix_shell.symbol = " ";
        lua.symbol = " ";
      };
    };
    # TODO: style bat properly
    bat = {
      enable = true;
      config = {
        map-syntax = [ "flake.lock:JSON" ];
        theme = "1337";
      };
    };
  };
}
