{ pkgs, lib, ... }:
let
  inherit (lib) getExe;
in
{
  # Shows kernel logs only on tty1
  boot.kernelParams = [ "console=tty1" ];
  services.greetd = {
    enable = true;
    vt = 2; # This prevents kernel logs from mangling greetd
    settings.default_session = {
      command = "${getExe pkgs.greetd.tuigreet} --time --cmd ${getExe pkgs.zsh}"; # Shell only by default
    };
  };

  # Launches hyprland, redirecting output to systemd journal
  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "launch-hyprland";
      text = ''
        systemd-cat --identifier hyprland Hyprland
      '';
    })
  ];

  security.pam.services.greetd.enableGnomeKeyring = true;
}
