{ self, ... }:
{
  lib,
  ...
}:
{
  imports = [ ./base-mod.nix ];

  nix.optimise = {
    automatic = true;
    dates = lib.mkForce [ "weekly" ];
  };

  # Have a predictable label for a managed NixOS system
  # The monitoring relies on this to determine when the deployment was done
  system.nixos.label = toString (
    self.shortRev or self.dirtyShortRev or self.lastModified or "unknown"
  );
}
