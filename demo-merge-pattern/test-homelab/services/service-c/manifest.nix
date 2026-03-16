# Public-only service (like gitea)
# No private counterpart

{ lib, serviceName, ... }:
{
  manifest = {
    module = ./service.nix;

    endpoints = {
      web = {
        port = 3000;
        protocol = "https";
      };
      ssh = {
        port = 22;
        protocol = "tcp";
      };
    };

    observability.metrics.impl = ./metrics.nix;

    dashboard = {
      category = "Dev";
      links = [{
        name = "Service C";
        description = "Public service";
        icon = "git";
      }];
    };
  };
}
