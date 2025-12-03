{
  services.ntpd-rs = {
    enable = true;
    useNetworkingTimeServers = false;
    settings = {
      server = [
        # Listen on all addresses, let `./firewall.nix` deal with it
        { listen = "0.0.0.0:123"; }
      ];
      source = [
        {
          mode = "nts";
          address = "time.cloudflare.com";
        }
        {
          mode = "nts";
          address = "oregon.time.system76.com";
        }
        {
          mode = "pool";
          address = "time.nist.gov";
        }
      ];
    };
  };
}
