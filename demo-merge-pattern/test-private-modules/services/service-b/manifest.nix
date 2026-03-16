# Private part of mixed service (like home-assistant private config)
# This will be merged with public manifest

{ lib, serviceName, ... }:
{
  manifest = {
    module = ./private-module.nix;  # Private-specific module

    # Add private endpoint
    endpoints.private-api = {
      port = 9002;
      protocol = "https";
    };

    # Add private observability
    observability.metrics.impl = ./metrics.nix;

    # Add to dashboard links (will concatenate with public)
    dashboard.links = [{
      name = "Service B Admin";
      description = "Private admin interface";
    }];
  };
}
