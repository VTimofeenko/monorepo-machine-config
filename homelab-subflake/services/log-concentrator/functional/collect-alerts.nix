/**
  Polls `srv:alert-manager` for its alerts, silenced and inhibited included.

  Rules evaluate every 60s, so an alert stays in alertmanager at least that
  long; a 15s poll sees every one. Resolved alerts drop out of the API.
*/
{ lib, ... }:
let
  inherit (lib.homelab.getManifest "alert-manager") endpoints;
in
{
  services.vector.settings = {
    sources.alert-manager-alerts = {
      type = "http_client";
      endpoint = "http://${lib.homelab.getServiceInnerIP "alert-manager"}:${toString endpoints.web.port}/api/v2/alerts";
      scrape_interval_secs = 15;
      scrape_timeout_secs = 10;
      decoding.codec = "json"; # The array becomes one event per alert
    };

    transforms.alerts-remap = {
      type = "remap";
      inputs = [ "alert-manager-alerts" ];
      source =
        # vrl
        ''
          receivers = array(.receivers) ?? []
          . = {
              "observed_at": .timestamp,
              "fingerprint": .fingerprint,
              "starts_at": .startsAt,
              "state": .status.state,
              "labels": .labels,
              "annotations": .annotations,
              "receivers": map_values(receivers) -> |r| { r.name },
              "silenced_by": .status.silencedBy,
              "inhibited_by": .status.inhibitedBy,
          }
        '';
    };
  };
}
