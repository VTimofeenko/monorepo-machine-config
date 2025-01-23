/**
  Configures bat
*/
{ lib, ... }:
let
  # `bat` config is called:
  # - programs.bat.settings in NixOS module
  # - programs.bat.config in home manager
  batSettings = {
    map-syntax = [ "flake.lock:JSON" ];
    theme = "Visual Studio Dark+"; # This looks OK with my terminal
  };
  bat = {
    enable = true;
  };
in
{
  # [25.05]
  # ```
  # nixosModule = {
  #   programs =
  #     {
  #       inherit bat;
  #     }
  #     |> lib.recursiveUpdate { bat.settings = batSettings; };
  # };
  # ```
  nixosModule =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.bat ];
    };
  homeManagerModule = {
    programs =
      {
        inherit bat;
      }
      |> lib.recursiveUpdate { bat.config = batSettings; };
  };
}
