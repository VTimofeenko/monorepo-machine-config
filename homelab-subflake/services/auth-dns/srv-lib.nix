{ lib, ... }:
let
  # DNS record formatters
  mkRecord =
    recordType: domainName: recordValue:
    "${domainName} IN ${recordType} ${recordValue}";
  mkARecord = mkRecord "A";
  mkCNAMERecord = domainName: recordValue: (mkRecord "CNAME" domainName (recordValue + "."));
  mkPTRRecord = domainName: recordValue: (mkRecord "PTR" domainName (recordValue + "."));
in
rec {
  # Re-export record formatters for internal use
  inherit mkRecord mkARecord mkCNAMERecord mkPTRRecord;

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
    Returns a list of forward zones that `auth-dns` manages

    Note: Reverse zones (in-addr.arpa) are handled separately via getReverseZones.
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

  /**
    Returns reverse zone information for DNS forwarding.

    Returns an attrset with:
      - reverseZones: List of specific reverse zones (e.g., ["1.168.192.in-addr.arpa."])
      - parentZones: List of parent zones that need nodefault (e.g., ["168.192.in-addr.arpa."])
  */
  getReverseZones =
    let
      inherit (lib.localLib) splitReverseJoin;

      # Get all network subnets and convert to reverse format
      # e.g., "192.168.1" -> "1.168.192"
      subnetsInArpa =
        lib.homelab.networks.getAll
        |> lib.mapAttrsToList (_: net: net.subnet)
        |> map splitReverseJoin;

      # Create specific reverse zones for each network
      # e.g., "1.168.192.in-addr.arpa."
      reverseZones = map (x: "${x}.in-addr.arpa.") subnetsInArpa;

      # Create parent zones that need nodefault
      parentZones =
        subnetsInArpa
        |> map (lib.splitString ".")
        |> map (parts:
          if (lib.elemAt parts 1) == "168" && (lib.elemAt parts 2) == "192" then
            "168.192.in-addr.arpa."
          else if (lib.last parts) == "10" then
            "10.in-addr.arpa."
          else if (lib.elemAt parts 1) == "16" && (lib.elemAt parts 2) == "172" then
            "16.172.in-addr.arpa."
          else
            # For other networks, use the parent class
            "${lib.concatStringsSep "." (lib.tail parts)}.in-addr.arpa."
        )
        |> lib.unique;
    in
    {
      inherit reverseZones parentZones;
    };

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

  /**
    Create base reverse zone configuration with SOA and NS records.

    Arguments:
      `reverseZone`: Reverse zone name (e.g., "1.168.192.in-addr.arpa")
      `forwardDomain`: Forward domain for this network (e.g., "home.arpa")
      `nameserverIPs`: List of nameserver IPs for NS records
      `ttl`: Zone TTL (default 604800)

    Returns NSD reverse zone config with SOA/NS headers as a string
  */
  mkReverseZoneBase =
    {
      reverseZone,
      forwardDomain,
      nameserverIPs,
      ttl ? 604800,
    }:
    ''
      $ORIGIN ${reverseZone}.
      $TTL ${toString ttl}

      @ IN SOA ns1.${forwardDomain}. admin.${forwardDomain}. (
          ${builtins.readFile ./serial} ; Serial
          28800      ; Refresh
          7200       ; Retry
          864000     ; Expire
          ${toString ttl} )   ; Minimum TTL

      ${lib.concatLines (lib.imap1 (i: _: "IN NS ns${toString i}.${forwardDomain}.") nameserverIPs)}

    '';
}
