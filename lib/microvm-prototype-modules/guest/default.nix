/**
  Guest-side microvm modules
*/
microVMName:
{
  impermanence,
  agenix,
  data-flake,
  lib,
  pkgs,
  ...
}:
{
  microvm.vms.${microVMName}.config = {
    imports = [
      impermanence.nixosModules.impermanence
      agenix.nixosModules.default
      data-flake.nixosModules.${microVMName}
      ./management.nix
      ./network.nix

      # TODO: Revisit this, maybe add more modules
      ../../../modules/nixOS/homelab/common/ship-logs.nix
    ];

    # Secrets setup
    age.identityPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

    # Persistence
    fileSystems."/persist".neededForBoot = lib.mkForce true;
    environment.persistence."/persist".directories = [ "/var/lib/nixos" ];

    microvm.shares = [
      {
        source = "/vms/${microVMName}";
        mountPoint = "/persist";
        tag = "persist";
        proto = "virtiofs";
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
  };
}
