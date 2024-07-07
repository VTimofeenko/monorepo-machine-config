/**
  FIXME: this services drops a core upon second start (cold start OK, restart -- core). Probably something to do with the env.
*/
{ osConfig, config, ... }:
let

  inherit (osConfig) my-data;
  ownLanIP = (my-data.lib.getOwnHostInNetwork "lan").ipAddress;
in
{
  imports = [ ./impl.nix ];

  services.my-wayvnc = {
    enable = true;
    settings = {
      address = ownLanIP;
      private_key_file = config.xdg.configHome + "/wayvnc/key.pem";
      certificate_file = config.xdg.configHome + "/wayvnc/cert.pem";
    };
  };
}
