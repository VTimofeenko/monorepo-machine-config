# https://www.home-assistant.io/integrations/prometheus/
{
  services.home-assistant = {
    extraComponents = [ "prometheus" ];
    # ACLs take care of that
    config.prometheus.requires_auth = false;
  };
}
