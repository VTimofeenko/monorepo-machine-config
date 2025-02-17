# Tiny module that provides configuration for homepage dashboard
{ config, lib, ... }:
let
  inherit (lib.homelab) getServiceConfig getService getSrvSecret;

  srvName = "home-dashboard";
  srvCfg = getServiceConfig srvName;
  srv = getService srvName;
in
{
  services.homepage-dashboard = {
    enable = true;
    inherit (srvCfg) bookmarks settings services;
  };

  systemd.services.homepage-dashboard = {
    serviceConfig = {
      # Use LoadCredential to inject the secrets into systemd unit. Works with DynamicUser which is what homepage-dashboard service uses.
      LoadCredential = lib.mapAttrsFlatten (
        name: _: "${name}:${config.age.secrets.${name}.path}"
      ) srv.secrets;
    };

    # Pass the secret paths in $CREDENTIALS_STORE to homepage-dashboard using %d placeholder
    environment = lib.mapAttrs' (
      name: _: lib.nameValuePair ("HOMEPAGE_FILE_" + (lib.toUpper name)) "%d/${name}"
    ) srv.secrets;
  };

  # Add homepage-dashboard specific secrets to agenix
  age.secrets = builtins.mapAttrs (name: _: { file = getSrvSecret srvName name; }) srv.secrets;

  imports = ./functional |> lib.fileset.fileFilter (file: file.hasExt "nix") |> lib.fileset.toList;
}
