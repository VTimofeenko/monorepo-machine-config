/**
  Configures bat
*/
{ lib, ... }:
let
  batSettings = {
    map-syntax = [ "flake.lock:JSON" ];
    theme = "TwoDark"; # This looks OK with my terminal
  };
  bat = {
    enable = true;
  };
  mod = mode: {
    programs =
      {
        inherit bat;
      }
      |> lib.recursiveUpdate { bat.${if mode == "nixos" then "settings" else "config"} = batSettings; };
  };
in
{
  nixosModule = mod "nixos";
  homeManagerModule = mod "home";
}
