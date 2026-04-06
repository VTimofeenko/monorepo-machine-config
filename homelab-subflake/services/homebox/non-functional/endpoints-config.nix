endpoints: { ... }:
{
  services.homebox.settings.HBOX_WEB_PORT = endpoints.web.port |> toString;
}
