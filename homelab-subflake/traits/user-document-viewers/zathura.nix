{
  programs.zathura = {
    enable = true;
    options = {
      # Allows `zathura` to use system clipboard
      selection-clipboard = "clipboard";
      database = "sqlite";
    };
  };

  xdg.mimeApps = {
    associations.added."application/pdf" = [ "org.pwmt.zathura.desktop" ];
    defaultApplications."application/pdf" = [ "org.pwmt.zathura.desktop" ];
  };
}
