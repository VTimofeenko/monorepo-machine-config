# [[file:../../new_project.org::*Hyprland config][Hyprland config:1]]
# System level configs required for hyprland
{ pkgs, ... }@inputs: # TODO: Antipattern, confusing inputs
{
  imports = [
    inputs.hyprland.nixosModules.default
  ];
  xdg.portal = {
    enable = true;
    config.common.default = [
      "hyprland"
    ];
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
  programs.hyprland = {
    enable = true;
    xwayland = {
      enable = true;
    };
  };

  # NOTE: needed for swaylock
  security.pam.services.swaylock.text =
    ''
      # Account management.
      account required pam_unix.so

      # Authentication management.
      auth sufficient pam_unix.so   likeauth try_first_pass
      auth required pam_deny.so

      # Password management.
      password sufficient pam_unix.so nullok sha512

      # Session management.
      session required pam_env.so conffile=/etc/pam/environment readenv=0
      session required pam_unix.so
    '';
  environment.systemPackages =
    with pkgs; [
      # needed because the user config references /etc stuff
      swaynotificationcenter
    ];
  services.xserver.gdk-pixbuf.modulePackages = [ pkgs.librsvg ];

}
# Hyprland config:1 ends here
