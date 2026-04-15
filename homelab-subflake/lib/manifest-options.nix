# NixOS module options schema for service manifests
# Defines structure and merge behavior of manifests

{ lib, ... }:
let
  inherit (lib) mkOption types;

  # Custom type: singular path syntax, multiple definitions merge into list
  # Public: module = ./service.nix;
  # Private: module = ./private.nix;
  # Result: module = [./service.nix ./private.nix]
  modulePathType = types.mkOptionType {
    name = "modulePath";
    description = "module path (multiple definitions merge into list)";
    check = v: types.path.check v;
    merge = loc: defs: lib.flatten (map (def: def.value) defs);
  };

  endpointType = types.submodule {
    options = {
      port = mkOption {
        type = types.port;
        description = "Port number";
      };
      protocol = mkOption {
        type = types.enum [
          "tcp"
          "udp"
          "https"
        ];
        description = "Protocol type";
      };
      path = mkOption {
        type = types.str;
        default = "/";
        description = "URL path for https endpoints";
      };
    };
  };

  linkType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Display name";
      };
      description = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      icon = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      absoluteURL = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      path = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      service = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
    };
  };

  # Single metrics exporter configuration
  metricsExporterType = types.submodule {
    options = {
      impl = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Metrics implementation module";
      };
      endpoint = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Which endpoint exposes metrics (inferred if null)";
      };
      path = mkOption {
        type = types.str;
        default = "/metrics";
        description = "Metrics path on the endpoint";
      };
    };
  };

  observabilityType = types.submodule {
    options = {
      metrics = mkOption {
        type = types.attrsOf metricsExporterType;
        default = { };
        description = ''
          Metrics exporters for this service/trait.

          Each exporter is exposed at:
            https://<service>.metrics.<domain>/metrics/<exporterName>

          Naming convention:
            - Single exporter: Use "main" as the exporter name
            - Multiple exporters: Use descriptive names (app, geo, infra, etc.)

          Examples:
            - Single exporter:
              metrics.main = { impl = ./metrics.nix; };

            - Multiple exporters:
              metrics.app = { impl = ./app-metrics.nix; endpoint = "web"; };
              metrics.geo = { impl = ./geo-metrics.nix; endpoint = "geo-exporter"; };

          Migration-friendly: Adding exporters doesn't break existing scrape configs.
        '';
      };
      alerts = mkOption {
        type = types.nullOr (
          types.submodule {
            options = {
              # Kept for compatibility, change later
              grafanaImpl = mkOption {
                type = types.nullOr types.path;
                default = null;
                description = "Path to Grafana alerting rules definition";
              };
              prometheusImpl = mkOption {
                type = types.nullOr types.path;
                default = null;
                description = "Path to Prometheus alerting rules definition";
              };
            };
          }
        );
        default = null;
      };
      logging = mkOption {
        type = types.nullOr (
          types.submodule {
            options = {
              impl = mkOption {
                type = types.nullOr types.path;
                default = null;
              };
            };
          }
        );
        default = null;
      };
      probes = mkOption {
        type = types.nullOr (
          types.submodule {
            options = {
              enable = mkOption {
                type = types.bool;
                default = false;
                description = "Whether Prometheus probing is enabled for this service";
              };
              ssl = mkOption {
                type = types.bool;
                default = false;
                description = "Whether probing checks an SSL certificate (enables auto-generated cert expiry alerts)";
              };
              impl = mkOption {
                type = types.nullOr types.path;
                default = null;
                description = "NixOS module enabling the probe exporter on the service host";
              };
              prometheusImpl = mkOption {
                type = types.nullOr types.path;
                default = null;
                description = "NixOS module configuring Prometheus scrape jobs for this service's probes";
              };
            };
          }
        );
        default = null;
      };
    };
  };

in
{
  options = {
    module = mkOption {
      type = types.nullOr modulePathType;
      default = null;
      description = "Main service module path (auto-collects for mixed services)";
    };

    endpoints = mkOption {
      type = types.attrsOf endpointType;
      default = { };
      description = "Service network endpoints";
      # Merge behavior: union of attrsets (automatic)
    };

    endpointsConfig = mkOption {
      type = types.nullOr types.anything;
      default = null;
      description = "Optional module to configure service ports (receives endpoints as arg)";
    };

    firewall = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Custom firewall module";
    };

    sslProxyConfig = mkOption {
      type = types.nullOr types.anything;
      default = null;
      description = "SSL proxy configuration";
    };

    observability = mkOption {
      type = observabilityType;
      default = { };
      description = ''
        Observability configuration.

        Metrics exporters merge across public/private manifests.
        Each exporter gets path-based routing at:
          https://<service>.metrics.<domain>/metrics/<exporterName>
      '';
    };

    backups = mkOption {
      type = types.nullOr (
        types.submodule {
          options = {
            paths = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "Paths to include in the backup";
            };
            exclude = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "Paths to exclude from the backup";
            };
            schedule = mkOption {
              type = types.str;
              default = "daily";
              description = "Backup schedule (OnCalendar value)";
            };
            localDB = mkOption {
              type = types.bool;
              default = false;
              description = "Also dump and back up the local PostgreSQL database";
            };
            localOnly = mkOption {
              type = types.bool;
              default = false;
              description = "Do not store backups remotely (local restic server only)";
            };
            serviceName = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Override the service name used in backup job IDs and secrets (useful for abbreviated names)";
            };
            backupName = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Override the backup name if only that needs to be abbreviated.";
            };
            extraConfig = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = ''
                Path to a NixOS module for additional backup customizations.
                Called via importApply with { serviceName } as static arg.
                Use this to override fields like dynamicFilesFrom or repository.
              '';
            };
          };
        }
      );
      default = null;
      description = "Backup configuration. Parameters are forwarded to mkBkp; extraConfig allows per-service overrides.";
    };

    storage = mkOption {
      type = types.nullOr types.anything;
      default = null;
      description = "Storage configuration";
    };

    dashboard = mkOption {
      type = types.nullOr (
        types.submodule {
          options = {
            category = mkOption {
              type = types.str;
              description = "Dashboard category";
            };
            links = mkOption {
              type = types.listOf linkType;
              default = [ ];
              description = "Dashboard links";
              # Lists automatically concatenate when merged
            };
          };
        }
      );
      default = null;
      description = "Dashboard integration";
    };

    documentation = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to service documentation (README.md)";
    };

    multiInstance = mkOption {
      type = types.bool;
      default = false;
      description = "Whether service supports multiple instances";
    };

    database = mkOption {
      type = types.nullOr types.anything;
      default = null;
      description = "Database module";
    };

    srvLib = mkOption {
      type = types.nullOr types.anything;
      default = null;
      description = "Service-specific utilities";
    };
  };
}
