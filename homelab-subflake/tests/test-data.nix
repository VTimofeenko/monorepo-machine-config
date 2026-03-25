/**
  Test data extension for DNS test VM.

  Extends data-flake with a minimal test host configuration
  that includes `dns` and `auth-dns` services.
*/
{ data-flake }:
let
  baseData = data-flake.data;
in
baseData
// {
  hosts.all = baseData.hosts.all // {
    dns-test-vm = {
      description = "Test VM for DNS services";
      groups = [
        "managed"
        "test"
      ];
      hostId = 999;
      hostName = "dns-test-vm";
      inRack = false;
      networks = {
        lan = {
          macAddr = "52:54:00:12:34:56";
        };
        backbone-inner = {
          pubKey = "test-pubkey-backbone-inner";
        };
      };
      # Service instances that will run on this VM
      servicesAt = [
        "test-auth-dns"
        "test-dns"
      ];
      # Minimal traits for a working system
      traitsAt = [
        "network-general-setup"
        "disable-docs"
      ];
      sshPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGtestkeytestkeytestkeytestkeytestkey test-vm";
      system = "x86_64-linux";
      settings = { };
    };
  };

  services.all = baseData.services.all // {
    test-auth-dns = {
      serviceName = "test-auth-dns";
      instance = "test";
      moduleName = "auth-dns";
      onHost = "dns-test-vm";
      groups = [
        "managed"
        "nonWeb"
        "test"
      ];
      centralSSL = false;
      sideEffectOnly = false;
    };

    test-dns = {
      serviceName = "test-dns";
      instance = "test";
      moduleName = "dns";
      onHost = "dns-test-vm";
      networkAccess = [ "lan" ];
      groups = [
        "managed"
        "nonWeb"
        "test"
      ];
      centralSSL = false;
      sideEffectOnly = false;
      settings = {
        # Minimal DNS configuration for testing
        upstream = [
          "1.1.1.1@853#cloudflare-dns.com"
        ];
        altUpstream = [
          "9.9.9.9@853#dns.quad9.net"
        ];
        # Domains to block (return 0.0.0.0)
        customBlocklist = [
          "flurry.com"
          "example.tld"
        ];
        clientsNonGrata = [ ];
      };
    };
  };

  # Extend the lan and backbone-inner networks with our test VM
  networks = baseData.networks // {
    lan = baseData.networks.lan // {
      hostsInNetwork = baseData.networks.lan.hostsInNetwork // {
        dns-test-vm = {
          description = "Test VM for DNS services";
          fqdn = "dns-test-vm.home.arpa";
          groups = [
            "managed"
            "test"
          ];
          hostId = 999;
          hostName = "dns-test-vm";
          inRack = false;
          ipAddress = "192.168.1.199";
          macAddr = "52:54:00:12:34:56";
          networks = {
            lan = {
              macAddr = "52:54:00:12:34:56";
            };
            backbone-inner = {
              pubKey = "test-pubkey-backbone-inner";
            };
          };
          servicesAt = [
            "test-auth-dns"
            "test-dns"
          ];
          traitsAt = [
            "network-general-setup"
            "disable-docs"
          ];
        };
      };
    };
    backbone-inner = baseData.networks."backbone-inner" // {
      hostsInNetwork = baseData.networks."backbone-inner".hostsInNetwork // {
        dns-test-vm = {
          description = "Test VM for DNS services";
          fqdn = "dns-test-vm.backbone-inner.home.arpa";
          groups = [
            "managed"
            "test"
          ];
          hostId = 999;
          hostName = "dns-test-vm";
          inRack = false;
          ipAddress = "10.200.0.199";
          pubKey = "test-pubkey-backbone-inner";
          networks = {
            lan = {
              macAddr = "52:54:00:12:34:56";
            };
            backbone-inner = {
              pubKey = "test-pubkey-backbone-inner";
            };
          };
          servicesAt = [
            "test-auth-dns"
            "test-dns"
          ];
          traitsAt = [
            "network-general-setup"
            "disable-docs"
          ];
        };
      };
    };
  };
}
