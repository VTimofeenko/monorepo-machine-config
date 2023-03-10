{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Video
    yt-dlp
    mpv
  ];
  # Configuration files
  environment.etc = {
    # judging by strace, mpv on NixOS expects it in etc.
    "mpv/mpv.conf".text = ''
      hwdec
      save-position-on-quit
    '';
    "mpv/input.conf".text = ''
      WHEEL_UP add volume 5
      # mouse wheel for sound control
      WHEEL_DOWN add volume -5
    '';
  };
}
