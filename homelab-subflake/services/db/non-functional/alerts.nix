{ serviceName, ... }:
{
  lib,
  ...
}:
{
  Emergency = [
    {
      title = "DB service down";
      query = "pg_up";
    }
    {
      title = "DB disk almost full";
      # Relies on the fact that there is a single DB instance
      query =
        let
          label = "mountpoint=~\"/var/lib/postgresql.*\", host=\"${
            serviceName |> lib.homelab.getServiceHost
          }\"";
        in
        "(((node_filesystem_avail_bytes{${label}} * 100) / node_filesystem_size_bytes{${label}}) < 10)";
      addVector = true;
    }
  ];
}
