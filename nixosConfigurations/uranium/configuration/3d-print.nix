{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.openscad
    pkgs.prusa-slicer
  ];
  fonts = {
    packages = builtins.attrValues {
      inherit (pkgs) roboto twitter-color-emoji font-awesome;
      inherit (pkgs.nerd-fonts) jetbrains-mono;
      inherit (pkgs) goldman good-timings russo-one; # My fonts
    };
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
