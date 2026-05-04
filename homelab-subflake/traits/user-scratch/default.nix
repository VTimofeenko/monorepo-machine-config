/**
  Temporary home for one-off packages before they earn a proper trait.
*/
{ pkgs, inputs, ... }:
{
  imports = [ inputs.xremap-flake.nixosModules.default ];

  services.xremap.enable = true;
  services.xremap.config.modmap = [
    {
      name = "Global";
      remap = {
        "CapsLock" = "Esc";
      }; # globally remap CapsLock to Esc
    }
  ];
  home-manager.users.spacecadet.home.packages = with pkgs; [
    pavucontrol
    blueman
  ];
}
