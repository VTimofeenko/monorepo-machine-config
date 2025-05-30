/**
  Home manager module that configures git and related packages.
*/
{ conventional-commit-helper }:
{
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) getExe;
  conventional-commit-helper-pkg = conventional-commit-helper.packages.${pkgs.stdenv.system}.default;
in
{
  imports = [
    (import ./lazygit.nix { inherit conventional-commit-helper-pkg; })
  ];
  home.packages = builtins.attrValues { inherit (pkgs) git git-crypt; } ++ [
    conventional-commit-helper-pkg
  ];

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
        dft = "difftool --tool=difftastic";
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
      extraConfig = {
        url."https://github.com/".insteadOf = [
          "gh:"
          "github:"
        ];
        "difftool \"difftastic\"".cmd = ''${getExe pkgs.difftastic} "$LOCAL" "$REMOTE"'';
        difftool.prompt = false; # Disables 'launch $TOOLNAME' prompt

        # Adds diffs to the commits window
        commit.verbose = true;
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
  };
}
