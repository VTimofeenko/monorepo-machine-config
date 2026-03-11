/**
  Configures applications that are used by users. Separate from
  `../base-wayland-environment` to keep git history cleaner.

  Formerly `modules/applications` and `modules/home-manager`
*/
{ inputs, ... }:
{
  imports = [
    ./user.nix
    ./firejail.nix
    ./flatpak.nix
    ./virtualization.nix
  ];

  home-manager.users.spacecadet.imports = [
    ./general-home-manager.nix
    ./file-associations.nix
    ./media.nix
    ./fonts.nix
    ./swayimg.nix
    ./zathura.nix
    ./my-vim-config.nix
    ./broot.nix
    ./packages.nix # Dumping ground for one-off things

    inputs.base.homeManagerModules.my-theme
    inputs.base.homeManagerModules.git
    inputs.base.homeManagerModules.zsh
    inputs.base.homeManagerModules.kitty
    inputs.base.homeManagerModules.ideavim
    inputs.base.homeManagerModules.emacs
  ];
}
