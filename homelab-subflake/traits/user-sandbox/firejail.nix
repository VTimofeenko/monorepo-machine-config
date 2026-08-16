/**
  Generic application-sandboxing mechanism. App-specific `firejail` wrappers
  live alongside the trait that installs the app.
*/
{ pkgs, ... }:
{
  programs.firejail.enable = true;

  home-manager.users.spacecadet.home.packages = [
    (pkgs.writeShellApplication {
      name = "firejail-kill-fuzzy";

      runtimeInputs = [
        pkgs.firejail # Better be `config.programs.firejail.package` but no such option as of Mar 11, 2026
        pkgs.fzf
        pkgs.gnused
        pkgs.gawk
        pkgs.findutils # `xargs` here
      ];

      text = ''
        firejail --list | fzf | sed 's;:; ;g' | awk '{print $1}' | xargs kill -9
      '';
    })
  ];
}
