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
    ];
    programs.browserpass.enable = true;
    programs.password-store = {
      enable = true;
      package = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
    };
    home.file.".icons/default".source = "${pkgs.vanilla-dmz}/share/icons/Vanilla-DMZ";
  };
}
