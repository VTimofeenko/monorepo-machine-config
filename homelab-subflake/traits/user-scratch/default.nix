/**
  Temporary home for one-off packages before they earn a proper trait.
*/
{ inputs, ... }:
{
  imports = [ inputs.xremap-flake.nixosModules.default ];

  services.xremap.enable = true;
  services.xremap.serviceMode = "user";
  services.xremap.userName = "spacecadet";
  services.xremap.withNiri = true;
  services.xremap.watch = true;
  # services.xremap.debug = true;
  # Workaround for https://github.com/xremap/nix-flake/issues/97 :
  # `wantedBy = [ "graphical-session.target" ]` does not imply ordering, so
  # xremap can start before niri (which holds graphical-session.target until
  # ready via Type=notify) has finished initializing.
  systemd.user.services.xremap.after = [ "graphical-session.target" ];
  services.xremap.config.modmap = [
    {
      name = "Global";
      remap = {
        "CapsLock" = "Esc";
      }; # globally remap CapsLock to Esc
    }
  ];
  services.xremap.config.keymap = [
    {
      name = "app-jump-repro";
      application.only = "kitty";
      remap = {
        "9" = "0";
      };
    }
  ];
}
