{ serviceName, ... }:
{
  Emergency = [
    {
      title = "Scrape is down";
      expr = ''absent(up{resource="srv:${serviceName}"}) or up{resource="srv:${serviceName}"} == 0'';
      description = "Cannot retrieve healthchecks status. Check network connection.";
    }
  ];
  Error = [
    {
      title = "Backup checks are down";
      expr = ''absent(hc_check_up{resource="srv:${serviceName}",name=~".*-backup$"}) or hc_check_up{resource="srv:${serviceName}",name=~".*-backup$"} == 0'';
    }
  ];
}
