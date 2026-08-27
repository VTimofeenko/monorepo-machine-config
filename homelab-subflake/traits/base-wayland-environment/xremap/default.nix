{ inputs, ... }:
{
  imports = [
    inputs.xremap-flake.nixosModules.default
    ./shortcuts.nix
    ./app-jumps.nix
  ];

  services.xremap = {
    enable = true;
    withWlroots = true;
    userName = "spacecadet";
    serviceMode = "user";
    watch = true;
  };

  # See ../../niri/xremap.nix for why this is needed: the xremap-flake NixOS
  # module's user-service path never sets `partOf`, so xremap.service outlives
  # graphical-session.target stopping and restarting.
  systemd.user.services.xremap.partOf = [ "graphical-session.target" ];
}
