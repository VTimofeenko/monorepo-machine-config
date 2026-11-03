# TODO: separate into own service (its logs are untagged until then)
{ pkgs-unstable, pkgs, ... }:
{
  services.flaresolverr = {
    enable = true;
    package = pkgs-unstable.flaresolverr;
  };

  services.linkwarden = {
    package = pkgs.linkwarden.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./linkwarden-flaresolverr.patch ];
    });
    environment.FLARESOLVERR_URL = "http://localhost:8191";
  };
}
