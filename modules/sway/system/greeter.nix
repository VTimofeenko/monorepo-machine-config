{ pkgs, lib, ... }:
{

  boot.kernelParams = [ "console=tty1" ];
  services.greetd = {
    enable = true;
    vt = 2;

    settings = {
      default_session = {
        # taken from https://github.com/apognu/tuigreet
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd ${pkgs.zsh}/bin/zsh";
        user = "greeter";
      };
    };
  };
}
