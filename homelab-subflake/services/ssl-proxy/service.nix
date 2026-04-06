/**
  Service implementation for the SSL proxy
*/
{ config, lib, ... }:
{
  age.secrets.ssl-cert = {
    owner = config.services.nginx.user;
    inherit (config.services.nginx) group;
  };
  age.secrets.ssl-key = {
    owner = config.services.nginx.user;
    inherit (config.services.nginx) group;
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
  };

  imports =
    # TODO: `lib.locallib.mkImportsFromDir` ?
    (lib.fileset.fileFilter (file: file.hasExt "nix") ./functional |> lib.fileset.toList)
    ++ [
      ./listen-address.nix
      ./utils.nix
      ./oauth2-proxy-config
    ];
}
