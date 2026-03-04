/**
  Home manager specific: sets up SSH_AUTH_SOCK through GPG.

  Necessary for hardware token SSH authentication.

  Occasionally causes extra copies of gpg to spawn. Needs tuning?
*/
{
  nixosModule = { };
  homeManagerModule =
    { config, lib, ... }:
    {
  # Set `SSH_AUTH_SOCK` <=> gpg-agent is enabled in home-manager
      programs.zsh.initContent = lib.optionalString config.services.gpg-agent.enable ''
        if [[ -z "$SSH_AUTH_SOCK" ]]; then
          export SSH_AUTH_SOCK="$(${config.programs.gpg.package}/bin/gpgconf --list-dirs agent-ssh-socket)"
        fi
      '';
    };
}
