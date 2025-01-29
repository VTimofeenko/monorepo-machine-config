# Home manager module that configures zsh
{ self, ... }:
{
  pkgs,
  config,
  lib,
  ...
}:
let
  commonSettings = import ../common { inherit pkgs config self; };

  inherit (config.my-colortheme) raw semantic;
in
{
  imports = [
    (import ../../config { inherit lib pkgs self; }).homeManagerModule
  ];

  programs = {
    zsh = {
      enable = true;
      # Type directory name -> cd there
      autocd = true;
      # Start in VI insert mode
      defaultKeymap = "viins";
      # Move the dotfiles to .config -- unclutter home dir
      dotDir = ".config/zsh";
      # History options
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
  };
}
