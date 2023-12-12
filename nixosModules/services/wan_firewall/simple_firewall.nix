# Simple firewall to get me started. Written by hand, no DSL
{ lib
, pkgs
, config
, ...
}:
let
  inherit (config) my-data;
  srvName = "wan_firewall";
  thisSrvConfig = my-data.lib.getServiceConfig srvName;

  wanFWHostSettings = my-data.lib.getOwnHostConfig;
  inherit (wanFWHostSettings) netInterfaces;

  extractName = name: netInterfaces.${name}.name;
  wan = extractName "wan";
  lan-bridge = extractName "lan-bridge";

  lanNet = my-data.lib.getNetwork "lan";
in
{
  # Enabled by hand and without mangling the chains
  # networking.nat.enable = true;
  boot = {
    kernelModules = [ "nf_nat_ftp" ];
    kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = lib.mkOverride 99 true;
      "net.ipv4.conf.default.forwarding" = lib.mkOverride 99 true;
    };
  };
  networking = {

    firewall.enable = lib.mkForce false; # Conflicts with nftables
    nftables.ruleset =
      ''
        table inet my_filter {
          set lan_dns {
            type ipv4_addr
            flags interval
            elements = { ${builtins.concatStringsSep ", " lanNet.dnsServers} }
          }

          chain common_chain {
            # Common rules
            iif lo accept comment "accept from localhost"
            ct state invalid drop comment "Drop invalid connections"
            ct state established,related accept comment "Accept traffic originated from us"
            return
          }

          chain incoming_from_lan {
              ip protocol icmp accept

              # TODO: when migrating to WG, disable!
              tcp dport 22 ct state new log prefix "New SSH connection: " group ${thisSrvConfig.logging.journaldAndPCAP.group} accept comment "SSH traffic"
              udp dport 67 accept comment "DHCP traffic"
              udp dport { 53, 853 } accept comment "DNS traffic"
          }

          chain prerouting {
            type nat hook prerouting priority -100;
            iifname "${lan-bridge}" ip daddr != @lan_dns udp dport 53 counter log prefix "RUNAWAY DNS " dnat to numgen inc mod 2 map { ${builtins.concatStringsSep ", " (lib.lists.imap0 (index: value: "${toString index} : ${value}") lanNet.dnsServers)} } comment "Force all DNS traffic to go through local DNS servers"

          }

          chain input {
            type filter hook input priority 0; policy accept;

            jump common_chain

            iifname "${lan-bridge}" ip saddr ${lanNet.subnet}.0/16 jump incoming_from_lan comment "LAN connection"
            # From archwiki, prevent icmp flood
            meta l4proto icmp icmp type echo-request limit rate over 10/second burst 4 packets drop comment "No ping floods"
            meta l4proto ipv6-icmp icmpv6 type echo-request limit rate over 10/second burst 4 packets drop comment "No ping floods"
            meta l4proto ipv6-icmp icmpv6 type { destination-unreachable, packet-too-big, time-exceeded, echo-reply, parameter-problem, mld-listener-query, mld-listener-report, mld-listener-reduction, nd-router-solicit, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert, ind-neighbor-solicit, ind-neighbor-advert, mld2-listener-report } accept comment "Accept ICMPv6"
            meta l4proto icmp icmp type { destination-unreachable, router-solicitation, router-advertisement, time-exceeded, parameter-problem } accept comment "Accept ICMP"

            # TODO: wireguard meshes

            drop
          }


          chain forward {
              type filter hook forward priority 0; policy drop

              jump common_chain

              # Allow outgoing traffic from your LAN
              iifname "${lan-bridge}" accept

              # Drop all other forwarded traffic by default
              log prefix "BAD FORWARD " drop
          }

          chain output {
              type filter hook output priority 0; policy accept;

              # Allow outgoing traffic
              oifname "${wan}" accept

              # Allow loopback interface traffic
              oifname "lo" accept
          }

          chain postrouting {
              type nat hook postrouting priority filter; policy accept;
              iifname "${lan-bridge}" oifname "${wan}" masquerade
          }
        }

        table netdev ingress_filter {
          # This sits in front of the traffic and drops weird stuff
          # Source: https://github.com/chayleaf/notnft
          chain ingress_common {
            iif lo accept
            tcp flags & (fin|syn) == (fin|syn) drop
            tcp flags & (syn|rst) == (syn|rst) drop
            tcp flags & (fin|syn|rst|psh|ack|urg) == 0 drop
            tcp flags syn tcp option maxseg size 0-500 drop
            ip saddr 127.0.0.1 drop
            ip6 saddr ::1 drop
            fib saddr . iif oif missing drop
            return
          }
          chain ingress_lan {
            # TODO: restore, this rule needs to be launched after udev assigns the right name. See ingress_wan
            # type filter hook ingress device "${lan-bridge}" priority -500; policy accept; # LAN_INGRESS_HOOK
            jump ingress_common
          }

          chain ingress_wan {
            # TODO: restore, this rule needs to be launched after udev assigns the right name. See ingress_lan
            # type filter hook ingress device "${wan}" priority -500; policy accept; # WAN_INGRESS_HOOK
            jump ingress_common
            # fib daddr . iif type != { local, broadcast, multicast } drop # poor man's bogon dropping?

            ip protocol == icmp icmp type == { info-request, address-mask-request, router-advertisement, router-solicitation, redirect } drop
            ip6 nexthdr == ipv6-icmp icmpv6 type == { mld-listener-query, mld-listener-report, mld-listener-reduction, nd-router-solicit, nd-router-advert, nd-redirect, router-renumbering } drop
            ip protocol == icmp limit rate 10/second accept
            ip6 nexthdr == ipv6-icmp limit rate 10/second accept
            ip protocol == icmp drop
            ip6 nexthdr == ipv6-icmp drop

            # ip protocol == { tcp, udp } th dport == { 22, 53, 80, 443, 853 } accept
            # ip6 nexthdr == { tcp, udp } th dport == { 22, 53, 80, 443, 853 } accept
          }
        }

        # TODO: special considerations for wireguard networks
        # TODO: black hole outgoing traffic from some of the hosts
        # TODO: control some hosts using special views (might need DNS too)
        # TODO: route some hosts through a specific outgoing interface
        # TODO: try routing from completely outside the network
        # TODO: ingress DDoS and weird stuff filtering
      '';
    nftables.preCheckRuleset =
      ''
        # Otherwise build environment utterly fails
        sed '/LAN_INGRESS_HOOK/d' -i ruleset.conf
        sed '/WAN_INGRESS_HOOK/d' -i ruleset.conf
      '';
  };
  environment.systemPackages = [ pkgs.fast-cli pkgs.speedtest-cli ];
}
