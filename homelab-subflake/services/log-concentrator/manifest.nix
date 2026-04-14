{ serviceName, ... }:
let
  vectorPort = 6000;
  syslogPort = 514;
  accessLogConcentratorPort = 9514;
  metricsPort = 8087;
  dnstapPort = 9001;
in
{
  module = ./log-concentrator.nix;

  endpoints = {
    vector = {
      port = vectorPort;
      protocol = "tcp";
    };
    syslog = {
      port = syslogPort;
      protocol = "udp";
    };
    access-logs = {
      port = accessLogConcentratorPort;
      protocol = "tcp";
    };
    dnstap = {
      port = dnstapPort;
      protocol = "tcp";
    };
    metrics = {
      port = metricsPort;
      protocol = "tcp";
    };
  };

  firewall = import ./non-functional/firewall.nix {
    inherit vectorPort syslogPort accessLogConcentratorPort;
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  observability = {
    metrics.main = {
      impl = ./non-functional/metrics.nix;
      path = "/";
      endpoint = "metrics";
    };
    alerts.grafanaImpl = import ./non-functional/alerts.nix { inherit serviceName; };
  };
}
