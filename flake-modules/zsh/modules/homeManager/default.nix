# Home manager module that configures zsh
{
  pkgs,
  config,
  lib,
  ...
}:
let
  commonSettings = import ../common { inherit pkgs config; };

  inherit (config.my-colortheme) raw semantic;
in
{
  home = {
    inherit (commonSettings) packages;
  };
  programs = {
    zsh = {
      enable = true;
      autosuggestion.enable = true;
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
          "k" # standalone "k" is usually mistyped up arrow
          "cd /tmp" # I usually don't care about what happens after I cd to tmp
        ];
        ignoreSpace = true; # Do not include lines that start with a space. On by default, but I want to make sure.
        path = "${config.xdg.dataHome}/zsh/zsh_history"; # unclutter profile
        share = true; # Share history between sessions. On by default, but I want to make sure
      };
      # initExtraBeforeCompInit # Extra commands that should be added to .zshrc before compinit.
      # W/A for missing completions
      # Source: https://github.com/nix-community/home-manager/issues/2562
      initExtraBeforeCompInit =
        let
          profileDir = config.home.profileDirectory;
        in
        ''
          fpath+=("${profileDir}"/share/zsh/site-functions "${profileDir}"/share/zsh/$ZSH_VERSION/functions "${profileDir}"/share/zsh/vendor-completions)
        '';
      # initExtraFirst # Commands that should be added to top of .zshrc.
      sessionVariables =
        commonSettings.variables
        //
        # TODO: move this ot DE configuration, doesn't really belong here?
        {
          BEMENU_OPTS = lib.concatStringsSep " " [
            "--tb  '${raw.color0."#hex"}'" # Title background
            "--tf  '#${raw.indigo."#hex"}'" # Title foreground
            "--fb  '#${raw.color0."#hex"}'" # Filter background
            "--ff  '#${raw.fg-main."#hex"}'" # Filter foregroun
            "--cb  '#${raw.color0."#hex"}'" # Cursor background
            "--cf  '#${raw.fg-main."#hex"}'" # Cursor foregroun
            "--nb  '#${raw.color0."#hex"}'" # Normal background
            "--nf  '#${raw.fg-main."#hex"}'" # Normal foreground
            "--hb  '#${raw.color0."#hex"}'" # Highlighted background
            "--hf  '#${semantic.activeFrameBorder."#hex"}'" # Highlighted foreground
            "--fbb '#${raw.color0."#hex"}'" # Feedback background
            "--fbf '#${raw.fg-main."#hex"}'" # Feedback foreground
            "--sb  '#${raw.color0."#hex"}'" # Selected background
            "--sf  '#${raw.fg-main."#hex"}'" # Selected foreground
            "--ab  '#${raw.color0."#hex"}'" # Alternating background color
            "--af  '#${raw.fg-main."#hex"}'" # Alternating foreground color
            "--scb '#${raw.color0."#hex"}'" # Scrollbar background
            "--scf '#${raw.fg-main."#hex"}'" # Scrollbar foreground
            "--width-factor 0.2"
          ];
        };

      # Plugin configuration
      plugins =
        commonSettings.packagePlugins
        ++ (
          with commonSettings.myPlugins;
          map (name: {
            inherit name;
            file = "${name}.zsh";
            src = baseDir;
          }) list
        );

      shellGlobalAliases = {
        G = "| rg";
        C = "| ccopy";
        # (V)iew in (V)im
        V = "| vim -R";
      };
      syntaxHighlighting.enable = true;

      inherit (commonSettings) shellAliases completionInit;
      initExtra =
        commonSettings.initExtra
        # set SSH_AUTH_SOCK <=> gpg-agent is enabled in home-manager
        + (
          if config.services.gpg-agent.enable then
            ''
              if [[ -z "$SSH_AUTH_SOCK" ]]; then
                export SSH_AUTH_SOCK="$(${config.programs.gpg.package}/bin/gpgconf --list-dirs agent-ssh-socket)"
              fi
            ''
          else
            ""
        );
    };
    direnv = {
      enable = true;
      config.warn_timeout = "15s";
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

    broot = {
      enable = true;
      settings = {
        modal = true;
        default_flags = "--sort-by-type-dirs-last";
      };
    };
  };
}
