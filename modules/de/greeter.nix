{ pkgs, ... }:
{
  boot.kernelParams = [ "console=tty1" ];
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd ${pkgs.zsh}/bin/zsh";
        user = "greeter";
      };
    };
  };

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
