{ pkgs, ... }:

{
  fonts = {
    fonts = with pkgs; [
      (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
      roboto
      twitter-color-emoji
      font-awesome
    ];
    fontconfig = {
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font" ];
        sansSerif = [ "Roboto" ];
        serif = [ "Roboto" ];
        emoji = [ "Twitter Color Emoji" ];
      };
    };
  };
}
