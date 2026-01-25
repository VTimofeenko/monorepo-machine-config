/**
  This is a tiny override that changes the behavior of the standard NixOS
  Wireguard peer hostname refresh timer.

  Original script (defined in
  `nixos/modules/services/networking/wireguard-networkd.nix`) effectively does
  a `networkctl reload` which causes a client to be disconnected.

  This script:

  - Does something <=> there are peers to resolve (`exit 0` otherwise)
  - Uses `wg set` to apply endpoint IP to the peer without reloading

  Why use it:

  Does not restart the connection and drop everything

  Why not use it:

  1. It manipulates the state of Wireguard adapter directly and
    `systemd-networkd` prefers to be the sole source of truth.
  2. I disabled IPv6 in `getent` call because I am not using it.
  3. Script does not update `networkd` internal state. Restart of `networkd`
    may reset the value set by the script, but it should be self-correcting
  4. The choice of DNS record is naive – it chooses the first returned IP which
    may be a caveat for round-robin scenarios
*/
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.networking.wireguard;
  inherit (lib)
    mkIf
    mkForce
    mapAttrs'
    nameValuePair
    filterAttrs
    filter
    concatMapStringsSep
    escapeShellArg
    ;

  refreshEnabledInterfaces = filterAttrs (
    name: interface: interface.dynamicEndpointRefreshSeconds != 0
  ) cfg.interfaces;

  generateRefreshOverride =
    name: interface:
    let
      peersWithEndpoints = filter (p: p.endpoint != null) interface.peers;

      updateScript = concatMapStringsSep "\n" (peer: ''
        ENDPOINT="${peer.endpoint}"
        HOST="''${ENDPOINT%:*} "
        PORT="''${ENDPOINT##*:}"
        # Resolve the IP
        RESOLVED_IP=$(${pkgs.glibc}/bin/getent ahostsv4 "$HOST" | ${pkgs.gawk}/bin/awk '{print $1}' | ${pkgs.coreutils}/bin/head -n 1)

        if [ -n "$RESOLVED_IP" ]; then
          # Update the peer endpoint without tearing down the interface
          ${pkgs.wireguard-tools}/bin/wg set "${name}" peer ${escapeShellArg peer.publicKey} endpoint "$RESOLVED_IP:$PORT"
        fi
      '') peersWithEndpoints;
    in
    nameValuePair "wireguard-dynamic-refresh-${name}" {
      # Override the destructive `networkctl reload` script
      script = mkForce (if peersWithEndpoints == [ ] then "exit 0" else updateScript);

      # Ensure we have the necessary tools
      path = mkForce (
        with pkgs;
        [
          coreutils
          gawk
          glibc
          wireguard-tools
        ]
      );
    };

in
{
  config = mkIf (cfg.enable && cfg.useNetworkd) {
    systemd.services = mapAttrs' generateRefreshOverride refreshEnabledInterfaces;
  };
}
