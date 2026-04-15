/**
  MicroVM guest infrastructure.

  Applied automatically to any host with `isMicroVM == true`.
  Covers everything a microvm guest needs that isn't service/secret-specific.
*/
{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  hostName = lib.homelab.getOwnHost.hostName;
  lan = lib.homelab.getNetwork "lan";
in
{
  imports = [
    inputs.microvm.nixosModules.microvm
    inputs.impermanence.nixosModules.impermanence
  ];

  # TODO: remove this post-deploy, should be managed by trait now
  services.openssh = {
    enable = true;
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
    settings.PermitRootLogin = lib.mkForce "yes";
  };
  users.users.root.openssh.authorizedKeys.keys = lib.homelab.getSettings.SSHKeys;

  networking.firewall.interfaces =
    [
      "phy-lan"
    ]
    |> map (it: {
      ${it}.allowedTCPPorts = [ 22 ];
    })
    |> lib.mergeAttrsList;

  # TODO: remove this post-deploy,
  systemd.network = {
    networks."10-lan" = {
      enable = true;
      name = "10-lan";
      matchConfig.Name = lib.mkForce "phy-lan";
      networkConfig = {
        DHCP = "no";
        Address = [ "${lib.homelab.getOwnIpInNetwork "lan"}/24" ];
        Gateway = lan.settings.defaultGateway.address;
        DNS = lan.dnsServers;
        LinkLocalAddressing = "no";
      };
    };

    links."10-phy-lan" = {
      enable = true;
      linkConfig.Name = "phy-lan";
      matchConfig.PermanentMACAddress = lib.homelab.getOwnHost.networks.lan.macAddr;
    };
  };

  networking.nftables.enable = true;
  networking.useNetworkd = true;
  networking.enableIPv6 = false;

  # Needs persistence
  age.identityPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

  # Persistence config
  fileSystems."/persist".neededForBoot = lib.mkForce true;
  environment.persistence."/persist" = {
    directories = [ "/var/lib/nixos" ];
    files = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

  # Swap
  zramSwap = {
    enable = true;
    memoryPercent = 50;
    algorithm = "lz4";
    priority = 100;
  };

  # MicroVM volumes and shares
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
      size = 10 * 1024; # MiB
    }
  ];

  system.stateVersion = "24.11";

  environment.systemPackages = [
    pkgs.lsof
    pkgs.inetutils
    pkgs.nftables
  ];
}
