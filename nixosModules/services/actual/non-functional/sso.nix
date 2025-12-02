{
  pkgs,
  lib,
  config,
  ...
}:
{
  services.actual.settings.loginMethod = "openid";

  systemd.services.actual.environment = {
    ACTUAL_OPENID_DISCOVERY_URL =
      "keycloak" |> lib.homelab.services.getSettings |> builtins.getAttr "discoverURL";
    ACTUAL_OPENID_CLIENT_ID =
      "actual" |> lib.homelab.services.getSettings |> builtins.getAttr "openid-client-id";
    ACTUAL_OPENID_SERVER_HOSTNAME = "https://${"actual" |> lib.homelab.getServiceFQDN}";
  };
  systemd.services.actual.serviceConfig = {
    ExecStart =
      ''
        export ACTUAL_OPENID_CLIENT_SECRET=$(/run/current-system/sw/bin/cat ''${CREDENTIALS_DIRECTORY}/openid-client-secret)
        ${config.services.actual.package |> lib.getExe}
      ''
      |> pkgs.writeShellScriptBin "runme"
      |> lib.getExe
      |> lib.mkForce;

    LoadCredential = [
      "openid-client-secret:${config.age.secrets."actual-client-secret".path}"
    ];
  };
}
