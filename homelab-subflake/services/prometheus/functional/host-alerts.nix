/**
  Generic alerting rules for hosts running the monitoring-source trait.

  Covers: disk space, memory, CPU saturation, clock drift, `systemd` units,
  SMART health, and NixOS build state.

  Labels (resource, host, etc.) are inherited from the scraped metric labels
  rather than being set statically, since a single rule group covers all hosts.
*/
{ lib, pkgs, ... }:
let
  mkRule = (lib.homelab.getSrvLib "prometheus").mkRule null;

  monitoredHosts = lib.homelab.traits.get "monitoring-source" |> builtins.getAttr "onHosts";

  # Regex selector matching only hosts in the monitoring-source trait
  hostSelector =
    monitoredHosts |> lib.concatStringsSep "|" |> (hosts: ''resource=~"host:(${hosts})"'');

  # Filesystem selector: skip virtual/read-only/boot mounts.
  fsSelector = ''${hostSelector},fstype!~"tmpfs|overlay|devtmpfs|squashfs|ramfs",mountpoint!~"/boot.*"'';

  # Collapse multiple mountpoints of the same device (bind mounts) into one
  # series per (resource, host, device) to avoid duplicate alerts.
  fsAvail = "min by (resource, host, device) (node_filesystem_avail_bytes{${fsSelector}})";
  fsSize = "min by (resource, host, device) (node_filesystem_size_bytes{${fsSelector}})";

  # Minimum absolute free space: avoids noise on multi-TB disks where a
  # percentage threshold alone is too sensitive (e.g. 20% of 12 terabytes = 2.4 terabytes free).
  minFreeBytesWarn = toString (50 * 1024 * 1024 * 1024); # 50 gigabytes

in
{
  services.prometheus.ruleFiles = [
    (pkgs.writeText "host-alerts.rules.json" (
      {
        groups = [
          {
            name = "host-generic";
            rules = [
              (mkRule "Critical" {
                title = "SMART disk failure";
                expr = "smartctl_device_smart_status{${hostSelector}} == 0";
                description = "SMART self-assessment reports a disk failure";
              })
              (mkRule "Error" {
                title = "Disk space critical";
                expr = "${fsAvail} / ${fsSize} < 0.05";
                description = "Filesystem has less than 5% free space";
              })
              (mkRule "Warning" {
                title = "Disk space low";
                expr = ''
                  (${fsAvail} / ${fsSize} < 0.20)
                  and (${fsAvail} < ${minFreeBytesWarn})
                  unless (${fsAvail} / ${fsSize} < 0.05)
                '';
                description = "Filesystem is between 80-95% full and less than 50 GiB free";
              })
              (mkRule "Warning" {
                title = "Low available memory";
                expr = ''
                  node_memory_MemAvailable_bytes{${hostSelector}}
                  / node_memory_MemTotal_bytes{${hostSelector}}
                  < 0.10
                '';
                description = "Available memory is below 10% of total";
              })
              (mkRule "Warning" {
                title = "High CPU load";
                expr = ''
                  node_load5{${hostSelector}}
                  / on(resource) group_left()
                    count by (resource) (node_cpu_seconds_total{${hostSelector},mode="idle"})
                  > 1
                '';
                description = "5-minute load average exceeds number of CPUs";
              })
              (mkRule "Warning" {
                title = "Systemd unit failed";
                expr = ''node_systemd_unit_state{${hostSelector},state="failed"} > 0'';
                description = "One or more systemd units are in failed state";
              })
              (mkRule "Notice" {
                title = "High service restart rate";
                expr = "increase(node_systemd_service_restart_total{${hostSelector}}[1h]) > 5";
                description = "A systemd service has restarted more than 5 times in the last hour";
              })
              (mkRule "Notice" {
                title = "Clock drift";
                expr = "abs(node_timex_offset_seconds{${hostSelector}}) > 0.1";
                description = "System clock is more than 100ms out of sync with NTP";
              })
              # TODO: fix `nixos_version_info` metric and re-enable
              # ```
              # (mkRule "Informational" {
              #   title = "Dirty NixOS build";
              #   expr = ''nixos_version_info{${hostSelector}} == 1'';
              #   description = "Host is running a locally-modified NixOS build";
              # })
              # ```
            ];
          }
        ];
      }
      |> builtins.toJSON
    ))
  ];
}
