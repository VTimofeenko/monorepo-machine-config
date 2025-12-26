{ pkgs, lib, ... }:
let
  inherit (lib) getExe;
in
{
  # Shows kernel logs only on tty1
  boot.kernelParams = [ "console=tty2" ];
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${getExe pkgs.greetd.tuigreet} --time --cmd ${getExe pkgs.zsh}"; # Shell only by default
    };
  };

  # Launches hyprland, redirecting output to systemd journal
  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "launch-hyprland";
      text = ''
        systemctl --user stop graphical-session.target
        uwsm start hyprland-uwsm.desktop
      '';
    })
  ];

  security.pam.services.greetd.enableGnomeKeyring = true;
}
