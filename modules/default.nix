# [[file:../new_project.org::*Common system configuration modules][Common system configuration modules:1]]
# These arguments are passed through specialArgs
{ pkgs
, config
, lib
, agenix
, home-manager
, wg-namespace-flake
, selfModules
, ...
}:
{
  imports = [
    # Modules from imports
    agenix.nixosModules.default
    home-manager.nixosModules.home-manager
    # wg-namespace-flake.nixosModules.default # NOTE: imported on a per-host basis

    # this flake's nixosModules
    selfModules.zsh
    selfModules.nix-config
    selfModules.tmux


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

  users.users.root.shell = pkgs.zsh;

  # Set editors on the system level
  environment.variables.SUDO_EDITOR = "nvim";
  environment.variables.EDITOR = "nvim";

  # Cross-compilation setup
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
# Common system configuration modules:1 ends here
