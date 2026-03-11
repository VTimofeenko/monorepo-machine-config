/**
  Configures applications that are used by users. Separate from
  `../base-wayland-environment` to keep git history cleaner.

  Formerly `modules/applications` and `modules/home-manager`
*/
{ inputs, ... }:
{
  imports = [
    ./firejail.nix
    ./flatpak.nix
  ];

  home-manager.users.spacecadet.imports = [
    ./general-home-manager.nix
    ./file-associations.nix
    ./media.nix
    ./swayimg.nix
    ./zathura.nix
    ./packages.nix # Dumping ground for one-off things
    inputs.base.homeManagerModules.kitty
    inputs.base.homeManagerModules.ideavim
    inputs.base.homeManagerModules.emacs
  ];
}
