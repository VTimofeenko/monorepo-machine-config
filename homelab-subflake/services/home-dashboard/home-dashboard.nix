# Tiny module that provides configuration for homepage dashboard
{ lib, ... }:
let
  inherit (lib.homelab) getServiceConfig;

  srvName = "home-dashboard";
  srvCfg = getServiceConfig srvName;
in
{
  services.homepage-dashboard = {
    enable = true;
    inherit (srvCfg) bookmarks settings;
  };

  # This bit of code allowed dynamically loading secrets into
  # homepage-dashboard by enumerating them from the service. It relied on a
  # (now, obsolete) function `getSrvSecret`. I am no longer using
  # homepage-dashboard to retrieve stuff from services, but leaving this in
  # case I ever want to come back to this pattern.
  # ```
  #   systemd.services.homepage-dashboard = {
  #     serviceConfig = {
  #       # Inject credentials for services so widgets work.
  #       #
  #       # Uses `LoadCredential` to inject the secrets into systemd unit. Works
  #       # with `DynamicUser` which is what homepage-dashboard service uses.
  #       LoadCredential = lib.mapAttrsToList (
  #         name: _: "${name}:${config.age.secrets.${name}.path}"
  #       ) srv.secrets;
  #     };
  #
  #     # Pass the secret paths in $CREDENTIALS_STORE to homepage-dashboard using %d placeholder
  #     environment = lib.mapAttrs' (
  #       name: _: lib.nameValuePair ("HOMEPAGE_FILE_" + (lib.toUpper name)) "%d/${name}"
  #     ) srv.secrets;
  #   };
  #
  #   # Add homepage-dashboard specific secrets to `agenix`
  #   age.secrets = builtins.mapAttrs (name: _: { file = getSrvSecret srvName name; }) srv.secrets;
  # ```

  imports = lib.localLib.mkImportsFromDir ./functional;
}
