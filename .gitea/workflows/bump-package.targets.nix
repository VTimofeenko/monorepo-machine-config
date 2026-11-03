/**
  List of target packages for manual maintenance.

  - Packages bumped by the scheduled run.
  - Format is `attr -> { args ? [ ]; skipPatch ? false; }`:
    - `args`: extra nix-update args
    - `skipPatch`: only propose bumps that change major.minor
*/
{
  apprise-api = [ ];
  conventional-commit-helper = [ ];
  filabridge = [ ];
  ha-floorplan = [ ];
  homebox-mcp = [ ];
  prometheus-mcp-server = [ ];
  prometheus-ssl-exporter = [ ];
  excalidash-backend = {
    skipPatch = true;
    # Upstream also tags dev builds like v0.6.3-dev.9477bed
    args = [
      "--version-regex"
      "^v(\\d+\\.\\d+\\.\\d+)$"
    ];
  };
  # Filter out upstream tags pre-releases like 2.0.0-omega2
  prusa-exporter = [
    "--version-regex"
    "^(\\d+\\.\\d+\\.\\d+)$"
  ];
}
