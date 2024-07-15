# [[file:../../new_project.org::*User hyprland config][User hyprland config:1]]
# Home manaager module to configure hyprland
# TODO: Cleanup this module
{
  pkgs,
  lib,
  osConfig,
  selfPkgs,
  selfHMModules,
  ...
}:
let
  # Example of using system-wide configuration in home-manager module
  inherit (osConfig.networking) hostName;

  inherit (osConfig.my-colortheme) raw semantic;

  selfPkgs' = selfPkgs.${pkgs.stdenv.system};

  # Custom lib.nix for module-specific logic
  modLib = import ./lib.nix;

  cliphist = "${pkgs.cliphist}/bin/cliphist";

  utils = import ./utils.nix pkgs;

  launchShortcuts = {
    "Return" = "exec, ${pkgs.kitty}/bin/kitty";
    "E" = "exec, ${pkgs.libsForQt5.dolphin}/bin/dolphin";
    # Launches wofi with icons
    "R" =
      let
        wofiWrapper = pkgs.writeShellScript "wofi-run-wrapper" ''
          # For some reason wofi still can't find my flatpak stuff
          XDG_DATA_DIRS=$XDG_DATA_DIRS:/usr/share:/var/lib/flatpak/exports/share/applications:$HOME/.local/share/flatpak/exports/share ${pkgs.wofi}/bin/wofi --show drun -I
        '';
      in
      "exec, ${wofiWrapper}";
  };
  shiftLaunchShortcuts = {
    "grave" = "exec, ${lib.getExe utils.scratchpad-terminal}";
  };
  # focusShortcuts =
  #   {
  #     "H" = "movefocus, l";
  #     "L" = "movefocus, r";
  #     "K" = "movefocus, u";
  #     "J" = "movefocus, d";
  #   };
  hyperBindings = {
    "E" = "focuswindow, ^(Emacs)$";
  };
  mergedConfig = builtins.concatStringsSep "\n" (
    builtins.attrValues (builtins.mapAttrs modLib.mkMainModBinding launchShortcuts)
    ++ builtins.attrValues (builtins.mapAttrs modLib.mkMainModShiftBinding shiftLaunchShortcuts)
    ++ builtins.attrValues (builtins.mapAttrs modLib.mkHyperBinding hyperBindings)
  );
in
{
  imports = [
    ./pyprland # (ref:pyprland-import)
    ./keybinds # (ref:hyprland-bindings-import)
    ./modes # (ref:hyprland-modes-import)
    (./per-host-configs + "/${hostName}.nix") # (ref:per-machine-hyprland-config)
    ./lock # (ref:lock-hyprland-import)
    ./theme # (ref:hyprland-theme-import)
    selfHMModules.hyprland-helpers
    ./systemd.nix
  ];

  services.hyprland-helpers.enable = true;



  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    xwayland.enable = true;
    extraConfig =
      ''
        exec-once = systemdctl --user start set-random-wallpaper.service
        env = LIBVA_DRIVER_NAME,${if hostName == "neptunium" then "nvidia" else "radeonsi"}
        env = XDG_SESSION_TYPE,wayland
        ${
          if hostName == "neptunium" then
            ''
              env = GBM_BACKEND,nvidia-drm
              env = __GLX_VENDOR_LIBRARY_NAME,nvidia
            ''
          else
            ""
        }
        env = WLR_NO_HARDWARE_CURSORS,1

        # Some default env vars.
        env = XCURSOR_SIZE,24

        monitor=DP-2,3440x1440@120.0,0x0,1.0
        monitor=DVI-D-1,1920x1080@119.982002,3440x0,1.0

        $pinentry = ^(pinentry-qt)$
        windowrule = float,$pinentry
        windowrule = float,xdg-desktop-portal-gtk
        windowrule = size 25% 20%,$pinentry
        windowrule = center,$pinentry
        windowrule = stayfocused,$pinentry
        windowrule = dimaround,$pinentry
        bind = $mainMod SHIFT, Space, focuscurrentorlast
        bind = $mainMod, Space, exec, ${lib.getExe selfPkgs'.hyprland-switch-lang-on-xremap}
      ''
      + mergedConfig;
  };
}
# User hyprland config:1 ends here
