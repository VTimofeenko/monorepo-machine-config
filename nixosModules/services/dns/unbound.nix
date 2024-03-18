# Module that configures Unbound for recursive DNS, DNSSEC and caching
{
  config,
  selfPkgs,
  lib,
  pkgs,
  ...
}:
let
  inherit (config) my-data;

  thisSrvConfig = my-data.lib.getServiceConfig "dns_1"; # FIXME: flaky _1 addressing
  clientNetViewName = "wg_client_network";

  inherit (import ./lib.nix) mkARecord;
  lan = my-data.lib.getNetwork "lan";
  client = my-data.lib.getNetwork "client";

  inherit (my-data.networks) zones;
  selfPkgs' = selfPkgs.${pkgs.system};
in
{
  services.unbound = {
    enable = true;
    resolveLocalQueries = false;
    localControlSocketPath = "/run/unbound/unbound.socket";
    settings = {
      server = {
        # IP-based access control section
        interface = # Where to listen on
          [
            (my-data.lib.getOwnHostInNetwork "lan").ipAddress # Listen in LAN
            (my-data.lib.getOwnHostInNetwork "client").ipAddress # Listen in client network
          ];
        access-control = [
          "${lan.subnet}.1${lan.settings.netmask} allow"
          "${client.settings.clientSubNet}.1/24 allow" # TODO: move netmask to settings? Or core network schema?
        ];

        # Custom records go here
        local-zone =
          (map (zone: ''"${zone}" nodefault'') zones) # forces unbound not to proxy DNS requests for these hosts
          ++ (map (zone: ''"${zone}" always_null'') thisSrvConfig.customBlocklist); # Reply 0.0.0.0 for these hosts
        domain-insecure = zones;
        include = "${selfPkgs'.hostsBlockList}";

        # Serve specific records to client network
        access-control-view = [ "${client.settings.clientSubNet}.1/24 ${clientNetViewName}" ];

        # Other settings
        cache-max-ttl = 86400;
        # Security
        # Harden against algorithm downgrade when multiple algorithms are
        # advertised in the DS record.
        harden-algo-downgrade = "yes";

        # RFC 8020. returns nxdomain to queries for a name below another name that
        # is already known to be nxdomain.
        harden-below-nxdomain = "yes";

        # Require DNSSEC data for trust-anchored zones, if such data is absent, the
        # zone becomes bogus. If turned off you run the risk of a downgrade attack
        # that disables security for a zone.
        harden-dnssec-stripped = "yes";

        # Only trust glue if it is within the servers authority.
        harden-glue = "yes";

        # Ignore very large queries.
        harden-large-queries = "yes";

        # Perform additional queries for infrastructure data to harden the referral
        # path. Validates the replies if trust anchors are configured and the zones
        # are signed. This enforces DNSSEC validation on nameserver NS sets and the
        # nameserver addresses that are encountered on the referral path to the
        # answer. Experimental option.
        harden-referral-path = "no";

        # Ignore very small EDNS buffer sizes from queries.
        harden-short-bufsize = "yes";

        # Refuse id.server and hostname.bind queries
        hide-identity = "yes";

        # Refuse version.server and version.bind queries
        hide-version = "yes";

        verbosity = 1;
        identity = "DNS";
        do-not-query-localhost = "no";
        # To enable monitoring
        extended-statistics = "yes";
        log-queries = "yes";
        log-replies = "yes";
        # add a "reply: prefix to the logs"
        log-tag-queryreply = "yes";
        log-local-actions = "yes";
      };
      view = [
        {
          name = clientNetViewName;
          local-zone = [ ''"${my-data.settings.publicDomainName}." static'' ];
          # NOTE: originally I had the idea of doing something like
          # $SRV_NAME > CNAME $HOST_NAME
          # $HOST_NAME gets resolved to 192.168 for LAN, $CLIENT_IP for client
          # Unfortunately it does not work, see https://github.com/NLnetLabs/unbound/issues/747
          local-data = lib.attrsets.mapAttrsToList (k: v: ''"${mkARecord k v}"'') thisSrvConfig.clientView;
          view-first = "yes";
        }
      ];
      # Ask NSD for data on entries in the custom zones
      stub-zone = map (zone: {
        name = zone;
        stub-addr = [ "127.0.0.1@${toString config.services.nsd.port}" ];
      }) zones;

      # Designated upstream
      forward-zone = [
        # To test DoT: https://www.jwillikers.com/dns-over-tls-with-unbound
        {
          name = ".";
          forward-addr = thisSrvConfig.upstream;
          forward-tls-upstream = "yes";
          forward-first = "no";
        }
        # NOTE: archive.ph needs special treatment.
        {
          name = "archive.ph";
          forward-addr = thisSrvConfig.altUpstream;
          forward-tls-upstream = "yes";
          forward-first = "no";
        }
      ];

      # TODO: Move to monitoring module?
      remote-control.control-enable = true;
    };
  };
}
