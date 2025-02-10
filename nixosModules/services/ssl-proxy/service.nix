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
    (
      # Collect the service modules from data-flake and self and construct the
      # virtual hosts
      data-flake.serviceModules
      # Add serviceModules from self
      |> lib.mergeAttrs self.serviceModules
      # Only interested in modules with 'ingress'
      |> lib.filterAttrs (_: builtins.hasAttr "ingress")
      # Only want ones that declare some sort of sslProxyConfig
      |> lib.filterAttrs (_: value: builtins.hasAttr "sslProxyConfig" value.ingress)
      # Extract the sslProxyConfig module
      |> lib.mapAttrsToList (_: value: value.ingress.sslProxyConfig)
    )
    # Add components of this service
    ++ (lib.fileset.fileFilter (file: file.hasExt "nix") ./functional |> lib.fileset.toList)
    ++ [ ./listen-address.nix ];
}
