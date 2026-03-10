{ config, lib, ... }:
{
  services.gitea = {
    mailerPasswordFile = config.age.secrets.gitea-mailer-password.path;

    settings.mailer = rec {
      ENABLED = true;
      PROTOCOL = "smtps";
      SMTP_ADDR = "mail" |> lib.homelab.getServiceConfig |> builtins.getAttr "smtphost";
      SMTP_PORT = "mail" |> lib.homelab.getServiceConfig |> builtins.getAttr "smtpport";
      USER = ("gitea" |> lib.homelab.getServiceConfig).mailer.user;
      FROM = "Gitea <${USER}>";
    };

    settings.service.ENABLE_NOTIFY_MAIL = true;
  };
}
