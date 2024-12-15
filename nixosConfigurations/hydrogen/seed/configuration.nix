# Seed config for hydrogen, to be used after formatting the disk
{ pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking = {

    hostName = "helium";
    wireless.enable = false;

    firewall.allowedTCPPorts = [ 22 ];
  };
  time.timeZone = "America/Los_Angeles";

  sound.enable = false;

  environment.systemPackages = with pkgs; [
    vim
    git
  ];

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDa78M7tTZW84yAsZuvgN1M6AUd3JB9wa8wMoR3cy59LtrU8FwHjJmCqlpyB7Wa9GrfJe7NEqJ077sYrGQZIw41xUJ7fKaa07Xj4GzASYTB0qlZrdr1WJ4XYif5eh7iXMps5F5saz0d3cJWOeKq6jSAwgkqT/tK5ykPm75uV0PyEvNI06pSqmJy+2VHUu1b3f/cwGHUrBzrJjLSvPBppRxpLc4nhNMIdf+G481MQHzCsdz0lIisGk4t+WcMPapH8nwSFDgKZ1ZesGqFaC/AvyRMuaASjFTk+eNMFgR5KQCCP48iaKkr/CGld9mGZyN8nQ9A0g6ckDQInnhef2EwVJFpfYktqBmi4DOfZksw65qY8eQFdQFxRoQ1D69fEsupX3AF0xgRPV+ByVxKCWz11CUR3+QhKJ7uzEhou/RS4GqG4TiR2+b0zMP/sGZwedNMJQYy1h3bfauo2NVmSJMFt8jKmb82tMcqCW6t71UITRmmluwDNHCyrVXLr3GrhOLylp+NBwzm33QlOZ3ExHV+77hM4vHJwpraR+WrzijzqwQ+ut9zNNWv87AS12++kOWsIZmIJk5idpAjUuxRI8ZjMHNZft9+jaARVVAyVFIzdegfLMJZIs8edaqGN1egERJ4FPU64aFosyymHLSmSAnVEIa7SB04BbWvE19kbRTdUG/Q1Q== cardno:000500006946"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAING/fy5GuSKLFcA/EY30jFDB9MOIoMQbSmaXY/FLjf2s cardno:15_146_736"
  ];

  system.stateVersion = "23.05";
  nix = {
    extraOptions = "experimental-features = nix-command flakes";
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}
