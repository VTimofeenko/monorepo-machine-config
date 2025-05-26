/**
  Configures bat
*/
{ lib, ... }:
let
  batSettings = {
    map-syntax = [ "flake.lock:JSON" ];
    theme = "Visual Studio Dark+"; # This looks OK with my terminal
  };
  bat = {
    enable = true;
  };
  mod = {
    programs =
      {
        inherit bat;
      }
      |> lib.recursiveUpdate { bat.settings = batSettings; };
  };
in
{
  nixosModule = mod;
  homeManagerModule = mod;
}
