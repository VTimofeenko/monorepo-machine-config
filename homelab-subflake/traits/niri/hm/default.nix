{ pkgs, lib, ... }:
let
  # Focuses the first open window whose app-id matches a regex, since
  # niri's `focus-window` action only takes a numeric window id (unlike
  # Hyprland's `focuswindow, class:...`). Backs the app-jump binds below,
  # which pair with `../xremap.nix`'s `app-jumps.nix` hyper-key combos.
  niriFocusApp = pkgs.writeShellApplication {
    name = "niri-focus-app";
    runtimeInputs = [
      pkgs.jq
      pkgs.niri
    ];
    text = ''
      pattern=$1
      id=$(niri msg --json windows | jq -r --arg pat "$pattern" \
        '[.[] | select(.app_id != null and (.app_id | test($pat)))] | first | .id // empty')
      if [ -n "$id" ]; then
        niri msg action focus-window --id "$id"
      fi
    '';
  };
in
{
  imports = [
    ./cursor.nix
    ./kanshi.nix
    ./lock.nix
    ./wlr-which-key
  ];

  xdg.configFile."niri/config.kdl" = {
    source = pkgs.replaceVars ./config.kdl {
      kitty = lib.getExe pkgs.kitty;
      centerpiece = lib.getExe pkgs.centerpiece;
      fuzzel = lib.getExe pkgs.fuzzel;
      grimblast = lib.getExe pkgs.grimblast;
      swayosdClient = lib.getExe' pkgs.swayosd "swayosd-client";
      playerctl = lib.getExe pkgs.playerctl;
      wlrWhichKey = lib.getExe pkgs.wlr-which-key;
      niriFocusApp = lib.getExe niriFocusApp;
    };
    force = true;
  };

  services.swayosd.enable = true;

  programs.kitty.enable = true;
  services.mako.enable = true;
  services.polkit-gnome.enable = true;
  # Niri auto-spawns xwayland-satellite on-demand as soon as an X11 client
  # connects (needs no config, just the binary on PATH) -- gets Steam,
  # Emacs's GUI mode, PrusaSlicer, and other X11-only apps working.
  # https://github.com/YaLTeR/niri/wiki/Xwayland#using-xwayland-satellite
  home.packages = with pkgs; [
    swaybg
    xwayland-satellite
  ];
}
