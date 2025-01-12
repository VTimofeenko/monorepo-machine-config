{ config, pkgs, ... }:
let
  settings.hostName = "neon";
in
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
  ];
  boot.loader = {

    # Use the systemd-boot EFI boot loader.
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking = {
    inherit (settings) hostName;
    wireless.enable = false;
    firewall.allowedTCPPorts = [ 22 ];
  };

  time.timeZone = "America/Los_Angeles";
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  environment.systemPackages = with pkgs; [
    vim
    gitMinimal
  ];
  system.stateVersion = "24.11"; # Did you read the comment?
  users.users.root.openssh.authorizedKeys.keys = config.my-data.settings.SSHKeys;
  nix = {
    extraOptions = "experimental-features = nix-command flakes";
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}
