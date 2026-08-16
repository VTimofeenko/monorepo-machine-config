{ pkgs-unstable, ... }:
{
  programs.mpv = {
    enable = true;
    bindings = {
      WHEEL_UP = "add volume 5";
      WHEEL_DOWN = "add volume -5";
      "Alt+h" = "add video-pan-x 0.05";
      "Alt+l" = "add video-pan-x -0.05";
      "Alt+k" = "add video-pan-y 0.05";
      "Alt+j" = "add video-pan-y -0.05";
    };
    config = {
      hwdec = true;
      save-position-on-quit = true;
    };
  };

  programs.yt-dlp = {
    enable = true;
    package = pkgs-unstable.yt-dlp; # Force pin unstable, moves fast
  };

  xdg.mimeApps =
    let
      mpv = [ "mpv.desktop" ];
      apps = {
        "video/mp4" = mpv;
        "video/x-matroska" = mpv;
        "video/webm" = mpv;
        "video/quicktime" = mpv;
        "video/x-msvideo" = mpv;
        "video/mpeg" = mpv;
        "audio/mpeg" = mpv;
        "audio/flac" = mpv;
        "audio/ogg" = mpv;
        "audio/x-wav" = mpv;
      };
    in
    {
      associations.added = apps;
      defaultApplications = apps;
    };
}
