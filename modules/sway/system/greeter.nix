{ pkgs, lib, config, ... }:
{

  boot.kernelParams = [ "console=tty1" ];
  services.greetd = {
    enable = true;
    vt = 2;

    settings = {
      default_session =
        let
          sway-launcher = pkgs.writeShellScript "sway-launcher" ''
            exec systemd-cat --identifier=sway ${pkgs.sway}/bin/sway ${if (config.networking.hostName == "neptunium") then "--unsupported-gpu" else ""}
          '';
        in
        {
          # taken from https://github.com/apognu/tuigreet
          # command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd ${sway-launcher}";
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd ${pkgs.zsh}/bin/zsh";
          user = "greeter";
        };
    };
  };
}
