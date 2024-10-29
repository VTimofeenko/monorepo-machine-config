{ pkgs, ... }:
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
  programs.yt-dlp.enable = true;

  # Local image editing and organizing
  home.packages = [
    pkgs.digikam
    pkgs.exiftool
  ];
}
