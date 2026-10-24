{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.spoolman;
in
{
  services.spoolman.environment = {
    SPOOLMAN_DB_TYPE = "postgres";
    SPOOLMAN_DB_HOST = "db" |> lib.homelab.getServiceFqdn;
    SPOOLMAN_DB_PORT = "5432";
    SPOOLMAN_DB_NAME = "spoolman";
    SPOOLMAN_DB_USERNAME = "spoolman";
  };

  /**
    The upstream module runs with `DynamicUser`, so the secret is passed as a
    systemd credential.

    `SPOOLMAN_DB_PASSWORD_FILE` is not used: Spoolman reads it verbatim,
    including the trailing newline the agenix `alnum` generator leaves in.
    `$(<file)` strips it.
  */
  systemd.services.spoolman.serviceConfig = {
    LoadCredential = [ "db-password:${config.age.secrets.spoolman-db-password.path}" ];
    ExecStart = lib.mkForce (
      pkgs.writeShellScript "spoolman-start" ''
        SPOOLMAN_DB_PASSWORD="$(<"$CREDENTIALS_DIRECTORY/db-password")"
        export SPOOLMAN_DB_PASSWORD
        exec ${lib.getExe' pkgs.spoolman "spoolman"} --host ${cfg.listen} --port ${toString cfg.port}
      ''
    );
  };
}
