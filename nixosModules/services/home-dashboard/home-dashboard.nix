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
    inherit (srvCfg) bookmarks settings;
  };

  systemd.services.homepage-dashboard = {
    serviceConfig = {
      # Inject credentials for services so widgets work.
      #
      # Uses `LoadCredential` to inject the secrets into systemd unit. Works
      # with `DynamicUser` which is what homepage-dashboard service uses.
      LoadCredential = lib.mapAttrsToList (
        name: _: "${name}:${config.age.secrets.${name}.path}"
      ) srv.secrets;
    };

    # Pass the secret paths in $CREDENTIALS_STORE to homepage-dashboard using %d placeholder
    environment = lib.mapAttrs' (
      name: _: lib.nameValuePair ("HOMEPAGE_FILE_" + (lib.toUpper name)) "%d/${name}"
    ) srv.secrets;
  };

  # Add homepage-dashboard specific secrets to `agenix`
  age.secrets = builtins.mapAttrs (name: _: { file = getSrvSecret srvName name; }) srv.secrets;

  imports = lib.localLib.mkImportsFromDir ./functional;
}
