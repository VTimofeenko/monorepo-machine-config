{ config, ... }:
{
  services.restic.server = {
    enable = true;
    privateRepos = true;
    extraFlags = [
      "--htpasswd-file"
      "${config.age.secrets.restic-server-htpasswd.path}"
    ];
  };
}
