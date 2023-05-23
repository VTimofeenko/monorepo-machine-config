# [[file:../../new_project.org::*Firejail][Firejail:1]]
{ pkgs, lib, ... }: {
  programs.firejail.enable = true;
  programs.firejail.wrappedBinaries = {
    thunderbird = {
      executable = "${lib.getBin pkgs.thunderbird}/bin/thunderbird";
      profile = "${pkgs.firejail}/etc/firejail/thunderbird.profile";
    };
    telegram-desktop = {
      executable = "${lib.getBin pkgs.tdesktop}/bin/telegram-desktop";
      profile = "${pkgs.firejail}/etc/firejail/telegram.profile";
    };
  };
  # Firejail-specific desktop shortcuts
  home-manager.users.spacecadet = { pkgs, ... }: {
    xdg.desktopEntries = {
      thunderbird = {
        # Taken from Thunderbird v 91.5.0
        name = "Thunderbird";
        comment = "🦊Firejailed";
        genericName = "Mail Client";
        exec = "thunderbird %U";
        icon = "thunderbird";
        terminal = false;
        mimeType = [ "text/html" "text/xml" "application/xhtml+xml" "application/vnd.mozilla.xul+xml" "x-scheme-handler/http" "x-scheme-handler/https" "x-scheme-handler/ftp" ];
      };
      telegram = {
        # Taken from Telegram v 3.1.11
        name = "Telegram";
        comment = "🦊Firejailed";
        exec = "telegram-desktop -- %u";
        icon = "telegram";
        terminal = false;
        mimeType = [ "x-scheme-handler/tg" ];
      };
    };
  };
}
# Firejail:1 ends here
