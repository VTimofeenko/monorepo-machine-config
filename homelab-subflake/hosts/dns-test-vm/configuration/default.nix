/**
  Minimal VM configuration for DNS testing.

  This is a simple QEMU VM that only runs dns and auth-dns services.
*/
{
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.loader.grub.device = "/dev/vda";
  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_blk"
  ];

  fileSystems."/" = {
    device = "/dev/vda1";
    fsType = "ext4";
  };

  # Networking with networkd
  networking.useDHCP = false;
  networking.useNetworkd = true;

  # Configure network interfaces
  systemd.network = {
    enable = true;

    # Primary interface with DHCP
    networks."10-eth0" = {
      matchConfig.Name = "eth0";
      networkConfig.DHCP = "yes";
    };

    # Dummy interface for LAN simulation
    netdevs."20-lan0" = {
      netdevConfig = {
        Name = "lan0";
        Kind = "dummy";
      };
    };

    networks."20-lan0" = {
      matchConfig.Name = "lan0";
      address = [ "192.168.1.199/24" ];
      networkConfig.ConfigureWithoutCarrier = true;
    };

    # Dummy interface for backbone-inner simulation
    netdevs."20-backbone0" = {
      netdevConfig = {
        Name = "backbone0";
        Kind = "dummy";
      };
    };

    networks."20-backbone0" = {
      matchConfig.Name = "backbone0";
      address = [ "10.200.0.199/24" ];
      networkConfig.ConfigureWithoutCarrier = true;
    };
  };

  # Enable SSH for VM access
  services.openssh.enable = true;
  users.users.root.password = "hunter2";

  # Enable serial console for non-graphical VM access with autologin
  boot.kernelParams = [ "console=ttyS0" ];
  services.getty.autologinUser = "root";

  # Add check script and tools to the system
  environment.systemPackages = with pkgs; [
    dnsutils # provides dig
    (writeScriptBin "check-dns" ''
      #!${bash}/bin/bash
      set -e
      set -x

      DNS_SERVER="192.168.1.199"
      PUBLIC_DOMAIN="${lib.homelab.getSettings.publicDomainName}"

      echo "=== DNS Test VM Checks ==="
      echo

      echo "1. Checking blocked domains return 0.0.0.0..."
      RESULT=$(${dnsutils}/bin/dig @$DNS_SERVER flurry.com A +short)
      if [[ "$RESULT" != "0.0.0.0" ]]; then
        echo "FAIL: flurry.com should return 0.0.0.0, got: $RESULT"
        exit 1
      fi
      echo "  ✓ flurry.com → 0.0.0.0"

      RESULT=$(${dnsutils}/bin/dig @$DNS_SERVER example.tld A +short)
      if [[ "$RESULT" != "0.0.0.0" ]]; then
        echo "FAIL: example.tld should return 0.0.0.0, got: $RESULT"
        exit 1
      fi
      echo "  ✓ example.tld → 0.0.0.0"
      echo

      echo "2. Checking CNAME records to home.arpa zone..."
      RESULT=$(${dnsutils}/bin/dig @$DNS_SERVER gitea.$PUBLIC_DOMAIN CNAME +short)
      if [[ ! "$RESULT" =~ home\.arpa ]]; then
        echo "FAIL: gitea.$PUBLIC_DOMAIN should return CNAME to home.arpa, got: $RESULT"
        exit 1
      fi
      echo "  ✓ gitea.$PUBLIC_DOMAIN → $RESULT"
      echo

      echo "3. Checking CNAME records to backbone-inner.home.arpa zone..."
      RESULT=$(${dnsutils}/bin/dig @$DNS_SERVER maindb.$PUBLIC_DOMAIN CNAME +short)
      if [[ ! "$RESULT" =~ backbone-inner\.home\.arpa ]]; then
        echo "FAIL: maindb.$PUBLIC_DOMAIN should return CNAME to backbone-inner.home.arpa, got: $RESULT"
        exit 1
      fi
      echo "  ✓ maindb.$PUBLIC_DOMAIN → $RESULT"
      echo

      echo "4. Checking metrics zone..."
      RESULT=$(${dnsutils}/bin/dig @$DNS_SERVER metrics.$PUBLIC_DOMAIN SOA +short)
      if [[ -z "$RESULT" ]]; then
        echo "FAIL: metrics.$PUBLIC_DOMAIN zone should exist"
        exit 1
      fi
      echo "  ✓ metrics.$PUBLIC_DOMAIN zone exists"
      echo "    SOA: $RESULT"
      echo

      echo "5. Checking reverse DNS (PTR records)..."
      # First test NSD directly
      RESULT=$(${dnsutils}/bin/dig @127.0.0.1 -p 5454 -x 192.168.1.199 +short)
      if [[ -z "$RESULT" ]]; then
        echo "FAIL: NSD reverse DNS for 192.168.1.199 should return a PTR record"
        echo "  Zone check:"
        ${dnsutils}/bin/dig @127.0.0.1 -p 5454 1.168.192.in-addr.arpa SOA +short
        exit 1
      fi
      echo "  ✓ NSD: 192.168.1.199 → $RESULT"

      # Then test through Unbound
      RESULT=$(${dnsutils}/bin/dig @$DNS_SERVER -x 192.168.1.199 +short)
      if [[ -z "$RESULT" ]]; then
        echo "FAIL: Unbound reverse DNS for 192.168.1.199 should return a PTR record"
        exit 1
      fi
      echo "  ✓ Unbound: 192.168.1.199 → $RESULT"
      echo

      echo "6. Checking local zone resolution..."
      RESULT=$(${dnsutils}/bin/dig @$DNS_SERVER home.arpa SOA +short)
      if [[ -z "$RESULT" ]]; then
        echo "FAIL: home.arpa zone should exist"
        exit 1
      fi
      echo "  ✓ home.arpa zone exists"
      echo

      RESULT=$(${dnsutils}/bin/dig @$DNS_SERVER backbone-inner.home.arpa SOA +short)
      if [[ -z "$RESULT" ]]; then
        echo "FAIL: backbone-inner.home.arpa zone should exist"
        exit 1
      fi
      echo "  ✓ backbone-inner.home.arpa zone exists"
      echo

      echo "=== All DNS checks passed! ==="
    '')
  ];

  system.stateVersion = "24.05";
}
