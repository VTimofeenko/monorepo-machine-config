# These arguments are passed through specialArgs
{ home-manager, selfModules, ... }:
{
  imports = [
    home-manager.nixosModules.home-manager

    # this flake's nixosModules
    selfModules.zsh
    selfModules.nix-config
    selfModules.tmux
    # selfModules.my-theme

    # local modules
    ./fonts.nix
    ./applications # (ref:applications-system-import)
    ./virtualization # (ref:virtualization-import)
    ./hardware # (ref:hardware-import)
    ./network # (ref:network-import)
    ./user # (ref:user-import)
  ];
  time.timeZone = "America/Los_Angeles";

  networking.useDHCP = false;

  # Set editors on the system level
  environment.variables.SUDO_EDITOR = "nvim";
  environment.variables.EDITOR = "nvim";

  # Cross-compilation setup
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  # Fixes some annoying services that won't quit
  services.logind.settings.Login.KillUserProcesses = true;
}
