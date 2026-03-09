{ serviceName, ... }:
{ lib, ... }:
let
  daysToExpireQuery = ''floor((ssl_cert_not_after{cn="*.${lib.homelab.getSettings.publicDomainName}"} - time())/86400)'';
in
{
  Alert = [
    {
      title = "${serviceName} service down";
      query = "up{job=\"${serviceName}-srv-scrape\"}";
    }
    {
      title = "SSL will expire very soon";
      query = ''${daysToExpireQuery} < 2'';
      addVector = true;
    }
  ];
  Informational = [
    {
      title = "Renew SSL cert";
      query = ''${daysToExpireQuery} < 15'';
      addVector = true;
    }
  ];
}
