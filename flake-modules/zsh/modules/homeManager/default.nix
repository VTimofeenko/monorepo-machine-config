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
