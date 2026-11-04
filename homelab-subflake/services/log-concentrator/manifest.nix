_:
{
  module = ./log-concentrator.nix;

  endpoints = {
    vector = {
      port = 6000;
      protocol = "tcp";
    };
    syslog = {
      port = 514;
      protocol = "udp";
    };
    access-logs = {
      port = 9514;
      protocol = "tcp";
    };
    dnstap = {
      port = 9001;
      protocol = "tcp";
    };
    firewall-logs = {
      port = 9515;
      protocol = "tcp";
    };
    metrics = {
      port = 8087;
      protocol = "tcp";
    };
  };

  firewall = ./non-functional/firewall.nix;

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  observability = {
    metrics.main = {
      impl = ./non-functional/metrics.nix;
      path = "/metrics";
      endpoint = "metrics";
    };
    logging.units = [ "vector.service" ];
  };
}
