{
  config,
  lib,
  self,
  ...
}:
self.serviceModules.ssl-proxy.srvLib.mkStandardProxyVHost {
  serviceName = "docspell";
  port = 7880;
  # Docspell deals with big files
  extraConfig = ''
    client_max_body_size 100M;
  '';
  onlyHumans = true;
  inherit config lib;
}
