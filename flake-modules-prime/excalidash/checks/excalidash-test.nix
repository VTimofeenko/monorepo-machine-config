/**
  Automated boot/smoke test for `services.excalidash`, wired up alongside
  the interactive demo (`../check.nix`) via the `checks/<stem>.nix` ->
  `perSystem.checks.<stem>` auto-discovery convention — so both
  `nix flake check` and a human poking at the VM cover the same module.

  This is the "consider a nixosTest" option: unlike `../check.nix` (built to
  be booted and clicked around in), this asserts the whole chain actually
  works headlessly — Postgres comes up, `excalidash-migrate` applies its
  migrations, `excalidash-backend` starts and serves through the local nginx
  — and fails the build with the captured journal if anything regresses
  (this caught a real bug during development: DynamicUser has no passwd
  entry, so Node's `os.homedir()`, used by Prisma's CLI during
  `excalidash-migrate`, threw `uv_os_homedir returned ENOENT` until `$HOME`
  was set explicitly in the unit).
*/
{ pkgs, ... }:
pkgs.testers.runNixOSTest {
  name = "excalidash";

  nodes.machine =
    { pkgs, ... }:
    {
      imports = [ ../nixos-module.nix ];

      services.postgresql = {
        enable = true;
        ensureDatabases = [ "excalidash" ];
        ensureUsers = [
          {
            name = "excalidash";
            ensureDBOwnership = true;
          }
        ];
        # Test only: passwordless local auth, matching ../check.nix.
        authentication = ''
          local all all trust
          host  all all 127.0.0.1/32 trust
        '';
      };

      services.excalidash = {
        enable = true;
        listenHost = "127.0.0.1";
        listenPort = 6767;
        backendPackage = pkgs.callPackage ../packages/excalidash-backend.nix { };
        frontendPackage = pkgs.callPackage ../packages/excalidash-frontend.nix { };
      };
    };

  testScript = ''
    machine.start()
    machine.wait_for_unit("postgresql.service")
    machine.wait_for_unit("excalidash-backend.service")
    machine.wait_for_unit("nginx.service")
    machine.wait_for_open_port(6767)
    # `wait_for_unit` only waits for systemd's "active" state, which fires as
    # soon as ExecStart launches node — not once it's actually bound the
    # port. Without this, the /api/ check below races the backend and can
    # hit nginx before it's listening (502, not the app itself).
    machine.wait_for_open_port(8000)

    # The SPA shell, served by nginx.
    machine.succeed("curl -sf http://127.0.0.1:6767/ | grep -q ExcaliDash")

    # `/api/` reaching the live backend through the proxy (a real app-level
    # response, not a connection error/502 — confirms Postgres + migrations
    # + the backend process are all actually wired up correctly).
    # (no `-f`: a 4xx here is a legitimate app response — auth/onboarding
    # state — not a curl failure; only a connection error/502 should fail.)
    machine.succeed(
        "curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:6767/api/drawings"
        " | grep -qE '^(200|401|409)$'"
    )
  '';
}
