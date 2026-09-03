/**
  Same as ../checks/excalidash-test.nix but for `database.sqlite` — no
  Postgres node needed; `excalidash-migrate` creates the sqlite file itself
  under the unit's own StateDirectory (`database.sqlite.path`'s default) on
  first boot.
*/
{ pkgs, ... }:
pkgs.testers.runNixOSTest {
  name = "excalidash-sqlite";

  nodes.machine =
    { pkgs, ... }:
    {
      imports = [ ../nixos-module.nix ];

      services.excalidash = {
        enable = true;
        listenHost = "127.0.0.1";
        listenPort = 6767;
        database.sqlite = { };
        backendPackage = pkgs.callPackage ../packages/excalidash-backend-sqlite.nix { };
        frontendPackage = pkgs.callPackage ../packages/excalidash-frontend.nix { };
      };
    };

  testScript = ''
    machine.start()
    machine.wait_for_unit("excalidash-backend.service")
    machine.wait_for_unit("nginx.service")
    machine.wait_for_open_port(6767)
    machine.wait_for_open_port(8000)

    # The migration actually created the sqlite file where `database.sqlite.path`
    # says it should be — not just that the unit reports "active".
    machine.succeed("test -s /var/lib/excalidash/excalidash.db")

    machine.succeed("curl -sf http://127.0.0.1:6767/ | grep -q ExcaliDash")

    # (see ../checks/excalidash-test.nix for why no `-f` here)
    machine.succeed(
        "curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:6767/api/drawings"
        " | grep -qE '^(200|401|409)$'"
    )
  '';
}
