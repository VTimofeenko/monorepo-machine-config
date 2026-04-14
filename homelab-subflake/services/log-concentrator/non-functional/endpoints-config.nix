endpoints: { ... }:
{
  services.vector.settings.sources.vector-log-concentrator = {
    type = "vector";
    address = "0.0.0.0:${endpoints.vector.port |> toString}";
  };
}
