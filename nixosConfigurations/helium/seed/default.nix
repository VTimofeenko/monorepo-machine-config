/**
  Seed config for helium.

  Helium will be launched as a VM.
*/
{ config, pkgs, ... }:
let
  hostName = "helium";
  stateVersion = "24.05";
in
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  boot.loader.grub = {
    enable = true;
    # device = "/dev/sda";
  };

  networking = {
    inherit hostName;
    wireless.enable = false;
    firewall.allowedTCPPorts = [ 22 ];
  };

  time.timeZone = "America/Los_Angeles";

  # Access
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };
  users.users.root.openssh.authorizedKeys.keys = config.my-data.settings.SSHKeys;

  environment.systemPackages = with pkgs; [
    vim
    gitMinimal
  ];

  sound.enable = false;
  system = {
    inherit stateVersion;
  };

  # Enable flakes
  nix = {
    extraOptions = "experimental-features = nix-command flakes";
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}
