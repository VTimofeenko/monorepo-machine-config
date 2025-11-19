/**
  Service implementation for the SSL proxy
*/
{
  config,
  lib,
  data-flake,
  self,
  ...
}:
{
  age.secrets."ssl-cert" = {
    file = lib.homelab.getSrvSecret "ssl-terminator" "cert";
    owner = config.services.nginx.user;
    inherit (config.services.nginx) group;
  };
  age.secrets."ssl-key" = {
    file = lib.homelab.getSrvSecret "ssl-terminator" "private-key";
    owner = config.services.nginx.user;
    inherit (config.services.nginx) group;
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
  };

  imports =
    let
      serviceManifests =
        # Collect the service manifests from data-flake
        data-flake.serviceModules
        # Add manifests from self
        |> lib.mergeAttrs self.serviceModules;
    in
    # This code constructs the virtual host configurations for the services
    (
      # construct the virtual hosts
      serviceManifests
      # Only interested in modules with 'ingress'
      |> lib.filterAttrs (_: builtins.hasAttr "ingress")
      # Only want ones that declare some sort of `sslProxyConfig`
      |> lib.filterAttrs (_: value: builtins.hasAttr "sslProxyConfig" value.ingress)
      # Extract the `sslProxyConfig` module
      |> lib.mapAttrsToList (_: value: value.ingress.sslProxyConfig)
    )
    # Create dedicated paths for metrics
    ++ (
      serviceManifests
      |> lib.filterAttrs (_: v: v.observability.metrics.enable or false)
      # Exclude ones with "`addr`" specified – those have custom listeners
      |> lib.filterAttrs (_: v: !v.observability.metrics ? "port")
      |> lib.mapAttrsToList (
        serviceName: srvManifest:
        (import ./srv-lib.nix).mkMetricsPathAllowOnlyPrometheus {
          inherit serviceName lib;
          metricsPath =
            srvManifest.observability.metrics.path |> (it: if lib.isFunction it then it lib else it);
          # TODO: implement `metricsProxyPass` for services that may serve metrics from different ports
        }
      )
    )
    # Add components of this service
    ++ (lib.fileset.fileFilter (file: file.hasExt "nix") ./functional |> lib.fileset.toList)
    ++ [
      ./listen-address.nix
      ./utils.nix
      ./oauth2-proxy-config
    ];
}
