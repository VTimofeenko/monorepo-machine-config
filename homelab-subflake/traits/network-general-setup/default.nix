{
  networking = {
    firewall.enable = true;
    nftables.enable = true;
    useNetworkd = true;
  };

  services.resolved.enable = true;
}
