# Tiny module that provides configuration for homepage dashboard
{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (config) my-data;
  srvName = "home-dashboard";
  srvCfg = my-data.lib.getServiceConfig srvName;
  srv = my-data.lib.getService srvName;

  srvDataDir = "/var/lib/homepage-dashboard";

  components =
    map
      (name: {
        inherit name;
        pkg = pkgs.writeTextDir "share/${name}.yaml" (builtins.toJSON srvCfg.${name});
      })
      [
        "services"
        "settings"
        "bookmarks"
        "widgets"
      ];
in
{
  # Enable the service
  services.homepage-dashboard.enable = true;
  systemd.services.homepage-dashboard = {
    serviceConfig = {
      /* Configure the dashboard using information from my-data

         Will overwrite all the yaml files that home-dashboard needs with symlinks ot paths in Nix store
      */
      ExecStartPost =
        map
          (
            component:
            "${pkgs.coreutils}/bin/ln --symbolic --force ${component.pkg}/share/${component.name}.yaml ${srvDataDir}"
          )
          components;

      # Use LoadCredential to inject the secrets into systemd unit. Works with DynamicUser which is what homepage-dashboard service uses.
      LoadCredential =
        lib.mapAttrsFlatten (name: _: "${name}:${config.age.secrets.${name}.path}")
          srv.secrets;
    };

    # Pass the secret paths in $CREDENTIALS_STORE to homepage-dashboard using %d placeholder
    environment =
      lib.mapAttrs' (name: _: lib.nameValuePair ("HOMEPAGE_FILE_" + (lib.toUpper name)) "%d/${name}")
        srv.secrets;
  };

  # Add homepage-dashboard specific secrets to agenix
  age.secrets =
    builtins.mapAttrs (name: _: { file = my-data.lib.getSrvSecret srvName name; })
      srv.secrets;
}
