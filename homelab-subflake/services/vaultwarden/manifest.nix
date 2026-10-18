{ ... }:
{
  module = ./vaultwarden.nix;

  endpoints.web = {
    port = 8222;
    protocol = "https";
  };

  endpointsConfig = import ./non-functional/endpoints-config.nix;

  # Attachments, sends and the JWT signing key; vault data lives in Postgres
  # Module uses the legacy `bitwarden_rs` dir name on stateVersion < 24.11.
  # Both listed: restic skips a missing path, fails only if all are missing.
  backups = {
    paths = [
      "/var/lib/vaultwarden"
      "/var/lib/bitwarden_rs"
    ];
    exclude = [
      "/var/lib/vaultwarden/tmp"
      "/var/lib/bitwarden_rs/tmp"
    ];
  };

  database = {
    create = true;
    impl = ./non-functional/database.nix;
  };

  dashboard = {
    category = "Home";
    links = [
      {
        name = "Vaultwarden";
        icon = "vaultwarden";
        description = "Password manager";
      }
    ];
  };

  documentation = ./README.md;
}
