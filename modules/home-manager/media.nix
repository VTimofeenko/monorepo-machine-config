# [[file:../../new_project.org::*Media config][Media config:1]]
{ pkgs, ... }: {
  programs.mpv = {
    enable = true;
    bindings = {
      WHEEL_UP = "add volume 5";
      WHEEL_DOWN = "add volume -5";
    };
    config = {
      hwdec = true;
      save-position-on-quit = true;
    };
  };
  programs.yt-dlp.enable = true;
}
# Media config:1 ends here
