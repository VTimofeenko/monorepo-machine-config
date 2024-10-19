{ pkgs, ... }:
{
  fonts = {
    packages = builtins.attrValues { inherit (pkgs) roboto twitter-color-emoji font-awesome; } ++ [
      (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
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
