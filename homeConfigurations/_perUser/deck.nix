{ lib, ... }:
{
  programs.kitty.package = lib.mkForce pkgs.hello; # Workaround for kitty not getting needed opengl on arch
}
