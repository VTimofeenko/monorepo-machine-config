/**
  Contains forced file assosciations with programs.
*/
let
  apps =
    let
      ff = [ "firefox.desktop" ];
      nvim = [ "nvim.desktop" ];
      swayimg = [ "swayimg.desktop" ];
    in
    {
      "application/pdf" = [ "org.pwmt.zathura.desktop" ];
      "text/html" = ff;
      "x-scheme-handler/http" = ff;
      "x-scheme-handler/https" = ff;
      "x-scheme-handler/chrome" = ff;
      "application/x-extension-htm" = ff;
      "application/x-extension-html" = ff;
      "application/x-extension-shtml" = ff;
      "application/x-extension-xhtml" = ff;
      "application/x-extension-xht" = ff;
      "application/rss+xml" = ff;
      "application/xhtml+xml" = nvim;
      "application/xhtml_xml" = nvim;
      "application/xml" = nvim;
      "image/gif" = swayimg;
      "image/jpeg" = swayimg;
      "image/png" = swayimg;
      "image/webp" = swayimg;
    };

in
{
  xdg.mimeApps = {
    enable = true;
    associations.added = apps;
    defaultApplications = apps;
  };
}
