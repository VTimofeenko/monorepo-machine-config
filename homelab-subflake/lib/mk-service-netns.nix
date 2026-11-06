/**
  Gives a service its own `backbone-inner` identity by running its units in a
  dedicated network namespace.

  The WireGuard interface is created in the host's namespace and then moved
  into the service's one[1]. Its UDP socket stays on the host, the service only
  sees the tunnel. With `egress = "clearnet"` the default route goes to the
  hub, which forwards it to WAN. If the tunnel is down, there is no egress.

  Identity comes from data-flake: `<service>.network.backbone-inner`. Other
  hosts learn the peer through the `backbone-inner-net` trait.

  #TODO: ACL: `clearnet` means unrestricted egress, as opposed to whitelisted
  #domain list. I need to come back to this.

  [1]: https://www.wireguard.com/netns/
*/
{
  serviceName,
  # systemd units to move into the namespace
  units ? [ serviceName ],
}:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  netName = "backbone-inner";
  net = lib.homelab.getNetwork netName;
  own = net.servicesInNetwork.${serviceName};
  hubName = "hydrogen";
  clearnet = (own.egress or null) == "clearnet";

  # Interface is created under a temporary name; `backbone-inner` is taken on
  # the host. Interface names are capped at 15 chars, hence the id
  tmpIfName = "bbi-srv-${lib.homelab.services.getId serviceName |> toString}";
  nsName = "srv-${serviceName}";

  # No keepalive: endpoints are static and the service's port is open on the
  # host, so either side can initiate a handshake
  mkPeerArgs =
    {
      pubKey,
      endpoint,
      allowedIPs,
    }:
    lib.escapeShellArgs [
      "peer"
      pubKey
      "endpoint"
      endpoint
      "allowed-ips"
      (lib.concatStringsSep "," allowedIPs)
    ];

  hostPeers =
    net.hostsInNetwork
    |> lib.mapAttrsToList (
      _: it:
      mkPeerArgs {
        inherit (it) pubKey;
        endpoint = "${lib.homelab.getHostIpInNetwork it.hostName "backbone"}:${toString net.port}";
        allowedIPs = [
          "${it.ipAddress}/32"
        ]
        ++ lib.optional (clearnet && it.hostName == hubName) "0.0.0.0/0";
      }
    );

  servicePeers =
    net.servicesInNetwork
    |> lib.filterAttrs (name: _: name != serviceName)
    |> lib.mapAttrsToList (
      _: it:
      mkPeerArgs {
        inherit (it) pubKey;
        endpoint = "${lib.homelab.getHostIpInNetwork it.onHost "backbone"}:${toString it.port}";
        allowedIPs = [ "${it.ipAddress}/32" ];
      }
    );

  inboundPorts =
    (lib.homelab.getManifest serviceName).endpoints
    |> lib.filterAttrs (_: it: it ? port && it.protocol != "udp")
    |> lib.mapAttrsToList (_: it: toString it.port);

  # TODO: ACLs here
  firewallRules = pkgs.writeText "${nsName}-netns.nft" ''
    table inet filter {
      chain input {
        type filter hook input priority 0; policy drop;
        ct state vmap { invalid : drop, established : accept, related : accept }
        iif "lo" accept
        meta l4proto { icmp, ipv6-icmp } accept
        ${lib.optionalString (inboundPorts != [ ]) ''
          iifname "${netName}" ip saddr { ${lib.concatStringsSep ", " lib.homelab.getSSLProxyIPs} } tcp dport { ${lib.concatStringsSep ", " inboundPorts} } accept
        ''}
      }
    }
  '';

  resolvConf = pkgs.writeText "${nsName}-resolv.conf" (
    net.dnsServers |> map (it: "nameserver ${it}") |> lib.concatLines
  );
in
{
  systemd.services = {
    "netns-${nsName}" = {
      description = "Network namespace with own ${netName} identity for ${serviceName}";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = [
        pkgs.iproute2
        pkgs.wireguard-tools
        pkgs.nftables
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "${lib.getExe' pkgs.iproute2 "ip"} netns del ${nsName}";
      };
      script = ''
        # Leftovers from an unclean stop
        ip netns del ${nsName} 2>/dev/null || true
        ip link del ${tmpIfName} 2>/dev/null || true

        ip netns add ${nsName}
        ip link add ${tmpIfName} type wireguard
        ip link set ${tmpIfName} netns ${nsName}
        ip -n ${nsName} link set ${tmpIfName} name ${netName}

        ip netns exec ${nsName} wg set ${netName} \
          private-key ${config.age.secrets."${serviceName}-${netName}-wg".path} \
          listen-port ${toString own.port} \
          ${lib.concatStringsSep " \\\n  " (hostPeers ++ servicePeers)}

        ip -n ${nsName} addr add ${own.ipAddress}${net.settings.netmask} dev ${netName}
        ip -n ${nsName} link set ${netName} mtu 1380 up
        ip -n ${nsName} link set lo up
        ${lib.optionalString clearnet "ip -n ${nsName} route add default dev ${netName}"}

        ip netns exec ${nsName} nft -f ${firewallRules}
      '';
    };
  }
  // lib.genAttrs units (_: {
    bindsTo = [ "netns-${nsName}.service" ];
    after = [ "netns-${nsName}.service" ];
    serviceConfig = {
      NetworkNamespacePath = "/run/netns/${nsName}";
      BindReadOnlyPaths = [ "${resolvConf}:/etc/resolv.conf" ];
    };
  });

  # Handshakes for the service arrive at the host
  networking.firewall.interfaces.backbone.allowedUDPPorts = [ own.port ];
}
