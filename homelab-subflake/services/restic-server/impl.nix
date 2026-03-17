{ config, pkgs, ... }:
{
  services.restic.server = {
    enable = true;
    privateRepos = true;
    extraFlags = [
      "--htpasswd-file"
      "${config.age.secrets.restic-server-htpasswd.path}"
    ];
  };

  # Needed for testing/examining backups
  environment.systemPackages = [ pkgs.restic ];
}
