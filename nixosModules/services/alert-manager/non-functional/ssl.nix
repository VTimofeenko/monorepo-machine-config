{
  serviceName,
  servicePort,
  ...
}:
{
  config,
  lib,
  self,
  ...
}:
{
  imports = [
    (self.serviceModules.ssl-proxy.srvLib.mkStandardProxyVHost {
      port = servicePort;
      inherit config lib serviceName;
      onlyHumans = true;
      extraConfig = "allow ${lib.homelab.getServiceIP "grafana"};\n";
    })
  ];
}
