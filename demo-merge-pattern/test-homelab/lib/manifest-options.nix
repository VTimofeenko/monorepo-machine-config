# NixOS module options schema for service manifests
# This defines the structure and merge behavior of manifests

{ lib, config, ... }:
let
  inherit (lib) mkOption types;

  # Custom type that allows singular path but merges multiple definitions into a list
  modulePathType = types.mkOptionType {
    name = "modulePath";
    description = "module path (multiple definitions merge into list)";
    check = v: types.path.check v;
    merge = loc: defs:
      # Collect all defined paths into a flat list
      lib.flatten (map (def: def.value) defs);
  };

  endpointType = types.submodule {
    options = {
      port = mkOption {
        type = types.port;
        description = "Port number";
      };
      protocol = mkOption {
        type = types.enum [ "tcp" "udp" "https" ];
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
    };
  };

  observabilityType = types.submodule {
    options = {
      metrics = mkOption {
        type = types.nullOr (types.submodule {
          options = {
            impl = mkOption {
              type = types.nullOr types.path;
              default = null;
            };
            endpoint = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
            path = mkOption {
              type = types.str;
              default = "/metrics";
            };
          };
        });
        default = null;
      };
      alerts = mkOption {
        type = types.nullOr (types.submodule {
          options = {
            grafanaImpl = mkOption {
              type = types.nullOr types.path;
              default = null;
            };
          };
        });
        default = null;
      };
    };
  };

in
{
  options.manifest = {
    # User-facing option: singular path syntax, but multiple definitions merge into list
    # Public manifest: module = ./service.nix;
    # Private manifest: module = ./private.nix;
    # Result: module = [ ./service.nix ./private.nix ]
    module = mkOption {
      type = types.nullOr modulePathType;
      default = null;
      description = "Main service module path (auto-collects for mixed services)";
    };

    endpoints = mkOption {
      type = types.attrsOf endpointType;
      default = {};
      description = "Service network endpoints";
      # Merge behavior: union of attrsets (automatic)
    };

    firewall = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Custom firewall module";
    };

    sslProxyConfig = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Custom SSL proxy config";
    };

    observability = mkOption {
      type = observabilityType;
      default = {};
      description = "Observability configuration";
      # Merge behavior: recursive merge (automatic)
    };

    dashboard = mkOption {
      type = types.nullOr (types.submodule {
        options = {
          category = mkOption {
            type = types.str;
            description = "Dashboard category";
          };
          links = mkOption {
            type = types.listOf linkType;
            default = [];
            description = "Dashboard links";
            # Lists automatically concatenate when merged
          };
        };
      });
      default = null;
      description = "Dashboard integration";
    };

    multiInstance = mkOption {
      type = types.bool;
      default = false;
      description = "Whether service supports multiple instances";
    };

    # Future fields can be added here...
  };
}
