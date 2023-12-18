{ config, pkgs, ... }:
{
  imports =
    [
      ./hardware-configuration.nix
      ./disk-config.nix
    ];
  boot.loader = {

    # Use the systemd-boot EFI boot loader.
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking = {
    hostName = "nitrogen";
    wireless.enable = false;
    firewall.allowedTCPPorts = [ 22 ];
  };

  time.timeZone = "America/Los_Angeles";
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  sound.enable = false;

  environment.systemPackages = with pkgs; [
    vim
    gitMinimal
  ];
  system.stateVersion = "23.11"; # Did you read the comment?
  users.users.root.openssh.authorizedKeys.keys = config.my-data.settings.SSHKeys;
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = "experimental-features = nix-command flakes";
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

}

