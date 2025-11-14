/**
  Sets up access logs aggregation from the `ssl-proxy`.
*/
{
  services.vector.settings.sources.access-log-concentrator = {
    type = "vector";
    address =
      let
        port = 9514;
      in
      "0.0.0.0:${port |> toString}"; # Listen on all interfaces, let firewall handle the access
  };
}
