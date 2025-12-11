{
  impermanence,
  lib,
  ...
}:
{
  imports = [
    impermanence.nixosModules.impermanence
  ];

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [
      "defaults"
      "size=25%"
      "mode=755"
    ];
  };

  users.users.root.hashedPasswordFile = "/persist/secrets/root-password";

  age.identityPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

  fileSystems."/persist" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    neededForBoot = true;
  };

  fileSystems."/nix" = {
    device = "/persist/nix";
    fsType = "none";
    options = [ "bind" ];
    neededForBoot = true;
  };

  fileSystems."/boot" = {
    device = "/persist/boot";
    fsType = "none";
    options = [ "bind" ];
  };

  # This is Raspberry Pi 3B with 1 gig of memory
  # Using zramSwap + mounting `/tmp` and `/var/tmp` back to the physical
  # device
  zramSwap.enable = true;
  zramSwap.memoryPercent = 50;

  fileSystems."/tmp" = {
    device = "/persist/tmp";
    fsType = "none";
    options = [ "bind" ];
  };

  fileSystems."/var/tmp" = {
    device = "/persist/var/tmp";
    fsType = "none";
    options = [ "bind" ];
  };

  # Persistence config
  environment.persistence."/persist" = {
    enable = true;
    directories = [
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
    ];
    files = (
      [
        "/etc/machine-id"
      ]
      ++ (lib.mapCartesianProduct ({ cypher, ext }: "/etc/ssh/ssh_host_${cypher}_key${ext}") {
        cypher = [
          "ed25519"
          "rsa"
        ];
        ext = [
          ""
          ".pub"
        ];
      })
    );
  };
}
