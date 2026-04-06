/**
  Set up mailer for Nextcloud
*/
# FIXME: `lib.homelab.services.getSettings` may be a legacy API — verify against
#        lib.homelab.getServiceConfig (used by other services e.g. gitea mailer).
#        Also verify `lib.homelab.getSettings.domain` is still the correct call.
{ lib, ... }:
{
  services.nextcloud.settings = rec {
    mail_smtpauth = true;
    mail_smtpport = 465;
    mail_smtpmode = "smtp";
    mail_smtpsecure = "ssl";
    mail_sendmailmode = "smtp";
    mail_from_address = "Nextcloud Mailer";
    mail_domain = lib.homelab.getSettings.domain;
    mail_smtpauthtype = "LOGIN";
    mail_smtphost = "mail" |> lib.homelab.services.getSettings |> builtins.getAttr "smtphost";
    mail_smtpname = "nextcloud.mailer@${mail_domain}";
  };
}
