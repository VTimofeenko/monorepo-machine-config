/**
  1. `nix build .#nixosConfigurations.sodium-seed.config.system.build.images.sd-card`
  2. `zstdcat ./result/sd-image/nixos-image-sd-card-*-aarch64-linux.img.zst | sudo dd of=/dev/sdb bs=4M status=progress conv=fsync`
  3. Insert the SD card
  4. Boot
  5. Wait
  6. Wait until reboot OK
  7. `ssh` in, grab public key
  8. Set up root password
  9. Edit `hosts.ncl`, optionally add host to `services.ncl` for Wi-Fi
  10. Generate secrets
  11. Don't forget to add WireGuard public keys to git
  12. `deploy-sodium --hostname <IP from DHCP> --magic-rollback false --auto-rollback false`

      Rollbacks are not needed since the network config will change dramatically
*/
{
  config,
  lib,
  ...
}:
let
  # Importing the old way since (as of writing) `lib` does not have `homelab`
  # attribute, so I can't use custom functions here.
  inherit (config) my-data;
in
{
  # Set up SSHd
  systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];
  users.users.root.openssh.authorizedKeys.keys = my-data.settings.SSHKeys;
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
    openFirewall = true;
  };

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  networking.hostName = "sodium";

  nix = {
    extraOptions = "experimental-features = nix-command flakes";
  };
  system.stateVersion = "25.05";
}
