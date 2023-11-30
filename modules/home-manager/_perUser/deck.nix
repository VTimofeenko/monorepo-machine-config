# [[file:../../../new_project.org::*Deck customization][Deck customization:1]]
{ pkgs, lib, ... }:
{
  programs.kitty.package = lib.mkForce pkgs.hello; # Workaround for kitty not getting needed opengl on arch # TODO: Figure this out
  home.username = "deck";
  home.homeDirectory = "/home/deck";
}
# Deck customization:1 ends here
