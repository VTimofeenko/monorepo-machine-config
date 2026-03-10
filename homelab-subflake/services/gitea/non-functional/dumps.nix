/**
  Set up local dumps for extra redundancy.
*/
{

  services.gitea.dump.enable = true;

  systemd.tmpfiles.rules = [
    "d /var/lib/gitea/dump 0755 gitea gitea 14d"
  ];
}
