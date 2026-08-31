/**
  Temporary home for one-off packages before they earn a proper trait.
*/
{ ... }:
{
  programs.localsend = {
    enable = true;
    openFirewall = true;
  };
}
