/**
  List of target packages for manual maintenance.

  - Packages bumped by the scheduled run.
  - Format is `attr -> extra nix-update args`.
*/
{
  apprise-api = [ ];
  conventional-commit-helper = [ ];
  filabridge = [ ];
  ha-floorplan = [ ];
  homebox-mcp = [ ];
  prometheus-mcp-server = [ ];
  prometheus-ssl-exporter = [ ];
  # Filter out upstream tags pre-releases like 2.0.0-omega2
  prusa-exporter = [
    "--version-regex"
    "^(\\d+\\.\\d+\\.\\d+)$"
  ];
}
