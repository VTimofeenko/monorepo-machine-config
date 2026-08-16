let
  apps = {
    "application/xhtml+xml" = [ "nvim.desktop" ];
    "application/xhtml_xml" = [ "nvim.desktop" ];
    "application/xml" = [ "nvim.desktop" ];
  };
in
{
  xdg.mimeApps = {
    associations.added = apps;
    defaultApplications = apps;
  };
}
