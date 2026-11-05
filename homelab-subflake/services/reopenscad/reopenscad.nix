{ lib, pkgs, ... }:
{
  services.reopenscad = {
    enable = true;
    package = pkgs.reopenscad.override {
      withPostgres = true;
      extraFonts = [
        {
          family = "Russo One";
          file = "${pkgs.russo-one}/share/fonts/truetype/RussoOne-Regular.ttf";
          description = "Heavy geometric display sans.";
        }
      ];
    };
    # Every request's Host header is checked against this
    publicOrigin = "https://${lib.homelab.getServiceFqdn "reopenscad"}";
    # Per-client rate limits key on the address the SSL proxy appends to X-Forwarded-For
    settings.REOPENSCAD_TRUSTED_PROXY_HOPS = "1";
  };
}
