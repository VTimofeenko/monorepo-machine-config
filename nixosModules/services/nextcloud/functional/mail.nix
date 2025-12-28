/**
  Set up mailer for Nextcloud
*/
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
