{ pkgs, ... }:
{
  home.packages = [ pkgs.libreoffice ];

  xdg.mimeApps =
    let
      writer = [ "writer.desktop" ];
      calc = [ "calc.desktop" ];
      impress = [ "impress.desktop" ];
      apps = {
        "application/vnd.oasis.opendocument.text" = writer;
        "application/msword" = writer;
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = writer;
        "application/rtf" = writer;
        "application/vnd.oasis.opendocument.spreadsheet" = calc;
        "application/vnd.ms-excel" = calc;
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = calc;
        "application/vnd.oasis.opendocument.presentation" = impress;
        "application/vnd.ms-powerpoint" = impress;
        "application/vnd.openxmlformats-officedocument.presentationml.presentation" = impress;
      };
    in
    {
      associations.added = apps;
      defaultApplications = apps;
    };
}
