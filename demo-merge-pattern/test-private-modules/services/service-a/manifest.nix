# Private-only service (like apprise)
# This is a NixOS module that sets manifest.* options

{ lib, serviceName, ... }:
{
  manifest = {
    module = ./service.nix;  # Would be actual path in real setup

    endpoints.web = {
      port = 9001;
      protocol = "https";
    };

    dashboard = {
      category = "Private";
      links = [{
        name = "Service A (Private)";
        description = "Private-only service";
      }];
    };
  };
}
