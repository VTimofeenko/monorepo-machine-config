{ lib, ... }:
let
  # DNS record formatters
  mkRecord =
    recordType: domainName: recordValue:
    "${domainName} IN ${recordType} ${recordValue}";
  mkARecord = mkRecord "A";
  mkCNAMERecord = domainName: recordValue: (mkRecord "CNAME" domainName (recordValue + "."));
in
rec {
  # Re-export record formatters for internal use
  inherit mkRecord mkARecord mkCNAMERecord;

  /**
    Get nameserver IPs for zone SOA/NS records.

    Returns IPs of DNS (Unbound) service instances, since that's what clients query.
    `auth-dns` (NSD) is localhost-only and not directly accessible to clients.
    Returns list of IPs (e.g., ["192.168.1.1", "192.168.1.2"])
  */
  getNameserverIPs =
    { lib }:
    lib.homelab.services.getAll
    |> lib.filterAttrs (_name: svcData: (svcData.moduleName or _name) == "dns")
    |> lib.attrNames
    |> map lib.homelab.getServiceInnerIP
    |> lib.take 2; # Typically `ns1` and `ns2`

  /**
    Create base zone configuration with SOA and NS records.

    Arguments:
      `domain`: Zone domain name (e.g., "srv.example.com")
      `nameserverIPs`: List of nameserver IPs for NS records
      `ttl`: Zone TTL (default 1800)

    Returns NSD zone config with SOA/NS headers as a string
  */
  mkZoneBase =
    {
      domain,
      nameserverIPs,
      ttl ? 604800,
    }:
    ''
      $ORIGIN ${domain}.
      $TTL ${toString ttl}

      @ IN SOA ns1.${domain}. admin.${domain}. (
          ${builtins.readFile ./serial} ; serial number
          28800 ; Refresh
          7200 ; Retry
          864000 ; Expire
          604800 ; Min TTL
          )

      ${lib.concatLines (lib.imap1 (i: _ip: "IN NS ns${toString i}.${domain}.") nameserverIPs)}

      ${lib.concatLines (lib.imap1 (i: ip: "ns${toString i} IN A ${ip}") nameserverIPs)}

    '';

  /**
    Returns a list of zones that `auth-dns` manages
  */
  getZones =
    let
      srvDomain = lib.homelab.getSettings.publicDomainName;
    in
    [
      srvDomain
      "metrics.${srvDomain}"
    ]
    ++
      # Assemble domains from networks
      (
        lib.homelab.networks.getAll
        |> builtins.mapAttrs (_: builtins.getAttr "domain")
        |> builtins.attrValues
      );

  mkZoneForNet =
    netName:
    let
      net = lib.homelab.getNetwork netName;
      zone = net.domain;
    in
    {
      ${zone}.data =
        [
          (mkZoneBase {
            domain = zone;
            nameserverIPs = net |> builtins.getAttr "dnsServers";
          })

          # Records for hosts
          (
            net.hostsInNetwork
            |> lib.mapAttrsToList (_: v: { inherit (v) hostName ipAddress; })
            |> map ({ hostName, ipAddress }: mkARecord hostName ipAddress)
          )

        ]
        |> lib.flatten
        |> lib.concatStringsSep "\n";
    };
}
