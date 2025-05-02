# https://www.home-assistant.io/integrations/prometheus/
_: {
  services.home-assistant = {
    extraComponents = [ "prometheus" ];
    config.prometheus = { };
  };
}
