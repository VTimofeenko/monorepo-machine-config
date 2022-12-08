{ pkgs, ... }:

{
  users.users.spacecadet = {
    isNormalUser = true;
    extraGroups = [ "wheel" "lp" ];
    shell = pkgs.zsh;
  };
  home-manager.users.spacecadet = { pkgs, ... }: {
    home.packages = with pkgs; [
      ncspot
      pavucontrol
      blueman
      zathura
      libreoffice
      firefox
      brave
      gthumb
      nextcloud-client
      pass
      (pass.withExtensions (ext: [ ext.pass-otp ]))
    ];
    programs.browserpass.enable = true;
    home.file.".icons/default".source = "${pkgs.vanilla-dmz}/share/icons/Vanilla-DMZ";
  };
}
