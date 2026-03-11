/**
  Creates firejailed desktop shortcuts.
*/
{ pkgs, lib, ... }:
{
  programs.firejail.enable = true;
  programs.firejail.wrappedBinaries = {
    thunderbird = {
      executable = "${lib.getBin pkgs.thunderbird}/bin/thunderbird";
      profile = "${pkgs.firejail}/etc/firejail/thunderbird.profile";
    };
    telegram-desktop = {
      executable = lib.getExe pkgs.telegram-desktop;
      profile = "${pkgs.firejail}/etc/firejail/telegram.profile";
    };
  };

  home-manager.users.spacecadet = _: {
    xdg.desktopEntries = {
      thunderbird = {
        # Taken from Thunderbird v 91.5.0
        name = "Thunderbird";
        comment = "🦊Firejailed";
        genericName = "Mail Client";
        exec = "thunderbird %U";
        icon = "thunderbird";
        terminal = false;
        mimeType = [
          "text/html"
          "text/xml"
          "application/xhtml+xml"
          "application/vnd.mozilla.xul+xml"
          "x-scheme-handler/http"
          "x-scheme-handler/https"
          "x-scheme-handler/ftp"
        ];
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

    home.packages = [
      (pkgs.writeShellApplication {
        name = "firejail-kill-fuzzy";

        runtimeInputs = [
          pkgs.firejail # Better be "config.programs.firejail.package" but no such option as of Mar 11, 2026
          pkgs.fzf
          pkgs.gnused
          pkgs.awk
          pkgs.findutils # `xargs` here
        ];

        text = ''
          firejail --list | fzf | sed 's;:; ;g' | awk '{print $1}' | xargs kill -9
        '';
      })
    ];
  };
}
