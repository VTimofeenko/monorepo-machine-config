{ config
, ...
}:
let
  inherit (config) my-data;

  srvConfig = my-data.lib.getServiceConfig "ntp";
in
{
  services.openntpd = {
    enable = true;
    servers = srvConfig.upstream;
    extraConfig =
      ''
        listen on ${(my-data.lib.getOwnHostInNetwork "lan").ipAddress}
      '';
  };
}
