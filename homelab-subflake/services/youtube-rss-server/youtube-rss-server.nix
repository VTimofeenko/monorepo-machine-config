/**
  Miniflux fetches feeds through the SSL proxy:

    https://<service FQDN>/feeds/videos.xml?channel_id=...
*/
{ config, ... }:
{
  services.youtube-rss-server = {
    enable = true;
    environmentFile = config.age.secrets.youtube-rss-server-api-key.path;
  };
}
