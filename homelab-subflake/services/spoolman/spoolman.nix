{ ... }:
{
  services.spoolman = {
    enable = true;
    environment = {
      # Only applies to SQLite; DB backups are the db service's job
      SPOOLMAN_AUTOMATIC_BACKUP = "FALSE";
    };
  };

  imports = [ ./fix-starlette-file-response.nix ];
}
