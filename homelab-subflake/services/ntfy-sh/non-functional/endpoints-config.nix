endpoints: { ... }:
{
  services.ntfy-sh.settings.listen-http = ":${endpoints.web.port |> toString}";
}
