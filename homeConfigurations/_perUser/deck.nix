{ pkgs, lib, config, ... }:
{
  programs.kitty.package = lib.mkForce pkgs.hello; # Workaround for kitty not getting needed opengl on arch
  home.username = "deck";
  home.homeDirectory = "/home/deck";
}
