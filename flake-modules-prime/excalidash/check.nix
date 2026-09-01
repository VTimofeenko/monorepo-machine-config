/**
  Demo VM for `services.excalidash` (this directory's `nixos-module.nix`) —
  wired up as a check (`nix build .#checks.<system>.excalidash`,
  or `nix run .#checks.<system>.excalidash.driverInteractive`-style access via
  `.config.system.build.vm`) rather than a `nixosConfigurations` entry, since
  auto-discovery (`lib/flake-module-loader.nix`) doesn't offer a
  `nixosConfigurations`/VM category — only a manual `default.nix` would, and
  this doesn't need the rest of that machinery.

  Not a `nixosTest`: this is meant to be booted and poked at interactively
  (`./result/bin/run-excalidash-demo-vm`), not asserted against in a
  `testScript`. Self-contained local Postgres (trust auth) + AUTH_MODE=local
  + auto-generated JWT/CSRF secrets — the same zero-config first-run shape as
  upstream's own `docker-entrypoint.sh`.

  Build + run:
    nix build .#checks.x86_64-linux.excalidash
    ./result/bin/run-nixos-vm
    # from the host once it's booted (port 16767, not 6767 — see `hostPort`
    # below):
    curl http://localhost:16767
*/
{ pkgs, lib, ... }:
let
  # Host-forwarded port the demo is actually reachable at from outside the
  # VM (see forwardPorts below) — 16767, not the guest-side 6767, since the
  # sandbox's live podman ExcaliDash instance already holds host port 6767.
  hostPort = 16767;
in
(import "${pkgs.path}/nixos/lib/eval-config.nix" {
  inherit lib;
  system = pkgs.stdenv.hostPlatform.system;
  modules = [
    ./nixos-module.nix

    # Use this same (overlaid) `pkgs` — it already has excalidash-backend /
    # excalidash-frontend from this flake's own overlayAttrs — instead of
    # letting eval-config import a fresh, un-overlaid nixpkgs.
    { nixpkgs.pkgs = pkgs; }

    (
      { ... }:
      {
        # --- VM/demo plumbing, not part of the module under test ---
        # `system.build.vm` is now `virtualisation.vmVariant.system.build.vm`
        # under the hood (see nixpkgs' virtualisation/build-vm.nix) — VM-only
        # overrides go under `virtualisation.vmVariant.*`, not top-level.
        virtualisation.vmVariant.virtualisation = {
          graphics = false;
          forwardPorts = [
            {
              from = "host";
              host.port = hostPort;
              guest.port = 6767;
            }
          ];
        };
        services.getty.autologinUser = "root";
        networking.firewall.enable = false;
        system.stateVersion = "24.11";

        services.postgresql = {
          enable = true;
          ensureDatabases = [ "excalidash" ];
          ensureUsers = [
            {
              name = "excalidash";
              ensureDBOwnership = true;
            }
          ];
          # Demo only: passwordless local auth so the module doesn't need a
          # `database.passwordFile` at all (DATABASE_URL composes without a
          # password segment when it's unset — see ./nixos-module.nix).
          authentication = ''
            local all all trust
            host  all all 127.0.0.1/32 trust
          '';
        };

        # --- the actual module under test ---
        services.excalidash = {
          enable = true;
          listenHost = "0.0.0.0";
          listenPort = 6767;
          openFirewall = true;
          # Origin the browser actually sees, through the host-port-forward
          # above — without this, the backend's CSRF/auth-origin check
          # rejects everything (production mode never allows the
          # any-localhost-port dev bypass; see ./nixos-module.nix).
          frontendUrl = "http://localhost:${toString hostPort}";
          # `check.nix` runs before this flake's own overlayAttrs is applied
          # back onto `pkgs` (and `virtualisation.vmVariant`'s
          # `extendModules` re-instantiation doesn't reliably carry a
          # `nixpkgs.pkgs` override down into its nested config either) — so
          # build these two directly rather than relying on `pkgs.<name>`.
          backendPackage = pkgs.callPackage ./packages/excalidash-backend.nix { };
          frontendPackage = pkgs.callPackage ./packages/excalidash-frontend.nix { };
          # authMode/jwtSecretFile/csrfSecretFile/database.passwordFile all
          # left at defaults: local auth, self-generated secrets, no DB password.
        };
      }
    )
  ];
}).config.system.build.vm
