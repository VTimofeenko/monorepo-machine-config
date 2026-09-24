/**
  ExcaliDash: self-hosted Excalidraw dashboard.

  Thin wrapper around the generic `services.excalidash` module
  (`inputs.base.nixosModules.excalidash`, already imported into every host
  via `baseFlakeModules` in `../../flake-lib.nix`) — this file only supplies
  homelab-specific secrets and the shared Postgres connection. Everything
  about how the app itself is packaged/served (backend package, local nginx
  serving the SPA + proxying `/api` + `/socket.io`) lives in that module.

  OIDC (Keycloak, via `non-functional/sso.nix`) is wired here. S3 file
  storage is supported both upstream and by the generic module (via
  `environment`/`secretFiles`) but not wired here.
*/
{ config, lib, ... }:
{
  services.excalidash = {
    enable = true;

    # Without this, the backend's CSRF/auth-origin check rejects everything
    # not exactly `http://localhost:6767` (its unset-default fallback) — it
    # never falls back to permitting arbitrary localhost origins in
    # production. See ../../../flake-modules-prime/excalidash/nixos-module.nix.
    frontendUrl = "https://${lib.homelab.getServiceFqdn "excalidash"}";

    database.postgresql = {
      host = "db" |> lib.homelab.getServiceFqdn;
      passwordFile = config.age.secrets.excalidash-db-password.path;
    };

    jwtSecretFile = config.age.secrets.excalidash-jwt-secret.path;
    csrfSecretFile = config.age.secrets.excalidash-csrf-secret.path;
    backendPort = 8001;
  };

  imports = [
    ./non-functional/sso.nix
  ];
}
