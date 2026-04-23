{ lib, config, inputs, ... }:
let
  # Checkout lives inside fava's own StateDirectory so the static fava user
  # can read it directly. fava-helper (DynamicUser, Group = "fava") writes here
  # via group permissions (StateDirectoryMode = "0770", UMask = "0027").
  repoPath = "/var/lib/fava/checkout";
  favaConfig = lib.homelab.getServiceConfig "fava";
in
{
  imports = [
    inputs.fava-helper.nixosModules.default
  ];

  services.fava = {
    enable = true;
    beancountFile = "${repoPath}/${favaConfig.beancountFile or "journal.beancount"}";
  };

  services.fava-helper = {
    enable = true;
    sshKeyCredential = config.age.secrets.fava-ssh-key.path;
    webhookSecretCredential = config.age.secrets.fava-webhook-secret.path;
    logLevel =  "fava_helper=debug";
    settings = {
      git = {
        repo_url = favaConfig.gitRepoUrl or "gitea@${lib.homelab.getServiceFqdn "gitea"}:spacecadet/budget";
        repo_path = repoPath;
        branch = favaConfig.gitBranch or "master";
        sync_interval = "5m";
      };
      # beancount_file is required by fava-helper whenever [metrics] is present.
      # Set it here so the field exists regardless of whether observability is wired.
      metrics.beancount_file = favaConfig.beancountFile or "journal.beancount";
    };
  };

  # fava-helper (DynamicUser) writes the checkout into fava's StateDirectory.
  # Group = "fava" makes created files group-owned by fava; UMask = "0027" makes
  # them group-readable. ReadWritePaths overrides the module default (/var/lib/fava-helper)
  # so ProtectSystem=strict allows writes into /var/lib/fava.
  systemd.services.fava-helper.serviceConfig = {
    Group = config.services.fava.group;
    UMask = "0027";
    ReadWritePaths = lib.mkForce [ "/var/lib/fava" ];
  };

  # The partition mounts at /var/lib/fava with root:root 755 (as formatted).
  # fava.service's StateDirectory would fix this, but fava-helper starts first.
  # tmpfiles.d runs after mounts but before services, so it wins the race.
  systemd.tmpfiles.rules = [ "d /var/lib/fava 0770 fava fava -" ];

  systemd.services.fava-helper.unitConfig = {
    StartLimitBurst = 3;
    StartLimitIntervalSec = 60;
  };
}
