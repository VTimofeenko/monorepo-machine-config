{ config, ... }:
{
  services.restic.server = {
    enable = true;
    extraFlags = [
      "--htpasswd-file"
      "${config.age.secrets.restic-server-htpasswd.path}"
    ];
  };
}
