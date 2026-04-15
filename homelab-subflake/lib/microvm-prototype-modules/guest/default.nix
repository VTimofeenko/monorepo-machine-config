/**
  Guest-side microvm infrastructure.

  Module resolution (services/traits/secrets) and impermanence injection
  are handled by `mkMicroVMHostModule` in `flake-lib.nix`.
*/
{ lib, pkgs, ... }:
let
  hostName = lib.homelab.getOwnHost.hostName;
in
{
  # Secrets
  age.identityPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

  # Persistence
  fileSystems."/persist".neededForBoot = lib.mkForce true;
  environment.persistence."/persist".directories = [ "/var/lib/nixos" ];

  # Swap
  zramSwap = {
    enable = true;
    memoryPercent = 50;
    algorithm = "lz4";
    priority = 100;
  };

  microvm.shares = [
    {
      source = "/vms/${hostName}";
      mountPoint = "/persist";
      tag = "persist";
      proto = "virtiofs";
    }
  ];

  fileSystems."/var/lib".neededForBoot = true;
  microvm.volumes = [
    {
      image = "/var/lib/microvms/${hostName}/data";
      mountPoint = "/var/lib";
      autoCreate = true;
      # In megabytes
      size = 10 * 1024;
    }
  ];

  system.stateVersion = "24.11";

  networking.useNetworkd = true;
  networking.enableIPv6 = false;

  environment.systemPackages = [
    pkgs.lsof
    pkgs.inetutils
    pkgs.nftables
    pkgs.vim
  ];
}
