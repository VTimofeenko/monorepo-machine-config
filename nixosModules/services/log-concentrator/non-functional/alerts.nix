{ serviceName, ... }:
{
  Emergency = [
    {
      title = "Scrape is down";
      query = "up{job=\"${serviceName}-srv-scrape\"}";
      description = "Log concentrator appears to be down.";
    }
  ];
}
