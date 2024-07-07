{ pkgs, ... }:
{
  boot.kernelParams = [ "console=tty1" ];
  services.greetd = {
    enable = true;
    vt = 2;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd ${pkgs.zsh}/bin/zsh";
        user = "greeter";
      };
    };
  };
}
