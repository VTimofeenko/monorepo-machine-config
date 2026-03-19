# Module that configures Unbound for recursive DNS, DNSSEC and caching
{
  lib,
  ...
}:
let
  inherit (lib.homelab)
    getServiceConfig
    getOwnIpInNetwork
    getOwnHost
    getService
    getSettings
    ;

  # Find which DNS service instance is running on this host
  ownHost = getOwnHost;
  dnsServiceName =
    ownHost.servicesAt
    |> builtins.filter (name: (getService name).moduleName == "dns")
    |> builtins.head;

  thisSrv = getService dnsServiceName;
  # Get service config using the actual instance name, not module name
  thisSrvConfig = getServiceConfig dnsServiceName;

  nsdPort = 5454; # TODO: get this from `nsd` manifest
  # TODO: migrate this into `srvLib`? Into data-flake?
  nsdZones = [
    "srv.${getSettings.publicDomainName}"
    "metrics.${getSettings.publicDomainName}"
    "backbone-inner.${getSettings.publicDomainName}"
    "mgmt.${getSettings.publicDomainName}"
    "db.${getSettings.publicDomainName}"
    "home.arpa"
  ];
in
{
  imports = lib.localLib.mkImportsFromDir ./functional ++ [
    # ACL configuration for client access control
    ./non-functional/acl.nix
  ];

  services.unbound = {
    enable = true;
    resolveLocalQueries = false;
    localControlSocketPath = "/run/unbound/unbound.socket";
    settings = {
      server = {
        # Where to listen on
        interface = map getOwnIpInNetwork thisSrv.networkAccess;

        # Custom records go here
        local-zone =
          (map (zone: ''"${zone}" nodefault'') nsdZones) # Forces unbound not to proxy DNS requests for these hosts
          ++ (map (zone: ''"${zone}" always_null'') thisSrvConfig.customBlocklist); # Reply 0.0.0.0 for these hosts
        domain-insecure = nsdZones;

        # Other settings
        cache-max-ttl = 86400;
        # Security
        # Harden against algorithm downgrade when multiple algorithms are
        # advertised in the record.
        harden-algo-downgrade = "yes";

        # RFC 8020 returns NXDomain to queries for a name below another name that
        # is already known to be NXDomain.
        harden-below-nxdomain = "yes";

        # Require DNSSEC data for trust-anchored `nsdZones`, if such data is absent, the
        # zone becomes bogus. If turned off you run the risk of a downgrade attack
        # that disables security for a zone.
        harden-dnssec-stripped = "yes";

        # Only trust glue if it is within the servers authority.
        harden-glue = "yes";

        # Ignore very large queries.
        harden-large-queries = "yes";

        # Perform additional queries for infrastructure data to harden the referral
        # path. Validates the replies if trust anchors are configured and the `nsdZones`
        # are signed. This enforces DNSSEC validation on nameserver NS sets and the
        # nameserver addresses that are encountered on the referral path to the
        # answer. Experimental option.
        harden-referral-path = "no";

        # Ignore very small `EDNS` buffer sizes from queries.
        harden-short-bufsize = "yes";

        # Refuse id.server and hostname.bind queries
        hide-identity = "yes";

        # Refuse version.server and version.bind queries
        hide-version = "yes";

        verbosity = 1;
        identity = "DNS";
        do-not-query-localhost = "no";

        # Not logging these as dnstap takes care of it
        log-queries = "no";
        log-replies = "no";
        # add a "reply: prefix to the logs"
        log-tag-queryreply = "no";
        log-local-actions = "no";
      };

      # Ask NSD for data on entries in the custom zones
      stub-zone = map (zone: {
        name = zone;
        stub-addr = [ "127.0.0.1@${toString nsdPort}" ];
      }) nsdZones;

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
    };
  };
}
