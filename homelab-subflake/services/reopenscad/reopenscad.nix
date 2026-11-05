{ lib, ... }:
{
  services.reopenscad = {
    enable = true;
    # Every request's Host header is checked against this
    publicOrigin = "https://${lib.homelab.getServiceFqdn "reopenscad"}";
    # Per-client rate limits key on the address the SSL proxy appends to X-Forwarded-For
    settings.REOPENSCAD_TRUSTED_PROXY_HOPS = "1";
  };
}
