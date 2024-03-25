/**
  Home manager module that configures git and related packages.
*/
{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) getExe;

  inherit (config.my-colortheme.semantic.hex) activeFrameBorder inactiveFrameBorder;
  inherit (config.my-colortheme.raw.hex) fg-main;
in
{
  home.packages = builtins.attrValues { inherit (pkgs) git git-crypt; };

  # Directory where local overrides can be places
  xdg.configFile."git/local.d/.keep".source = builtins.toFile "keep" "";
  programs = {
    git = {
      enable = true;
      aliases = {
        ci = "commit";
        st = "status";
        co = "checkout";
        rv = "remote --verbose";
        unstage = "reset HEAD --";
        # NOTE: Needs findutils xargs for -L1 argument
        pushall = "!git remote | ${pkgs.findutils}/bin/xargs -L1 git push --all";
        branch-note = "!git config branch.$(git symbolic-ref --short HEAD).note $( if [ $# -gt 0 ]; then $1; fi)";
      };
      userEmail = "id@vtimofeenko.com";
      userName = "Vladimir Timofeenko";
      ignores = [
        # Vim swap files
        "*.swp"
        # For Mac
        ".DS_STORE"
        # where envrc stores its stuff
        ".direnv/"
      ];
      extraConfig.url."https://github.com/" = {
        insteadOf = [
          "gh:"
          "github:"
        ];
      };
      includes = [
        { path = "~/.config/git/local.d/gitconfig"; } # Local ad-hoc overrides for git config
      ];
    };
    gh = {
      enable = true;
      settings.prompt = "enabled";
      settings.aliases.prco = "pr checkout";
    };
    lazygit = {
      enable = true;
      settings = {
        gui.theme = {
          selectedLineBgColor = [ "#${inactiveFrameBorder}" ];
          selectedRangeBgColor = [ "#${inactiveFrameBorder}" ];
          activeBorderColor = [
            "#${activeFrameBorder}"
            "bold" # Otherwise strikethrough creeps in for some reason
          ];
          inactiveBorderColor = [ "#${inactiveFrameBorder}" ];
          optionsTextColor = [ "#${fg-main}" ];
        };
        git.paging.pager = "${getExe pkgs.diff-so-fancy}";
      };
    };
  };
}
