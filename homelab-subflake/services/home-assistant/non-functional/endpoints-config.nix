endpoints: { lib, ... }:
{
  services.home-assistant.config.http = {
    server_port = endpoints.web.port;
    server_host = lib.homelab.getOwnIpInNetwork "backbone-inner";
    trusted_proxies = lib.homelab.getSSLProxyIPs;
    use_x_forwarded_for = true;
  };
}
