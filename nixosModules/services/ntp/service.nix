{
  services.ntpd-rs = {
    enable = true;
    useNetworkingTimeServers = true;
    settings = {
      server = [
        # Listen on all addresses, let `./firewall.nix` deal with it
        { listen = "0.0.0.0:123"; }
      ];
    };
  };
}
