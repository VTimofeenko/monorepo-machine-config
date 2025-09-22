{ config, ... }:
{
  services.tailscale = {
    enable = true;
    authKeyFile = config.age.secrets.tailscale.path;
    useRoutingFeatures = "server";
    extraUpFlags = [ "--advertise-exit-node" ];
  };
}
