# Public part of mixed service (like home-assistant public config)
# This will be merged with private manifest

{ lib, serviceName, ... }:
{
  manifest = {
    module = ./service.nix;  # Public module

    endpoints.web = {
      port = 8123;
      protocol = "https";
    };

    dashboard = {
      category = "Home";
      links = [{
        name = "Service B";
        description = "Main interface";
      }];
    };

    multiInstance = false;
  };
}
