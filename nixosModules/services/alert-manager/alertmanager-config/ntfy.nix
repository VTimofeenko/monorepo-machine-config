{ rcvName, address }:
{
  route.routes = [
    {
      receiver = rcvName;
      # Dispatch non-critical alerts only
      matchers = [ "alertLevel!=\"Emergency\"" ];
    }
  ];
  receivers = [
    {
      name = rcvName;
      webhook_configs = [
        {
          url = "http://${address}/hook";
          max_alerts = 3;
        }
      ];
    }
  ];
}
