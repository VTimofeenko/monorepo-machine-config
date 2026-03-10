/** TODO:

- Restore original wallpaper timer and stuff (see `./wallpaper-orig.nix`)
- Bring in my desktop images. Small package, get from filedump?
*/
{ pkgs, ... }:
{
  home.packages = [ pkgs.swww ];
}
