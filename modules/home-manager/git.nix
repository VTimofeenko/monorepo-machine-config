# [[file:../../new_project.org::*Git][Git:1]]
{ pkgs, ... }: {
  home.packages = builtins.attrValues {
    inherit (pkgs) git lazygit git-crypt;
  };

  # Directory where local overrides can be places
  xdg.configFile."git/local.d/.keep".source = builtins.toFile "keep" "";
  programs.git = {
    enable = true;
    aliases = {
      ci = "commit";
      st = "status";
      co = "checkout";
      rv = "remote --verbose";
      unstage = "reset HEAD --";
      pushall = "!git remote | xargs -L1 git push --all";
      branch-note = "!git config branch.$(git symbolic-ref --short HEAD).note $( if [ $# -gt 0 ]; then $1; fi)";
    };
    userEmail = "id@vtimofeenko.com";
    userName = "Vladimir Timofeenko";
    ignores = [
      # Vim swap files
      "*.swp"
      # For Mac
      ".DS_STORE"
    ];
    extraConfig = {
      url = {
        "https://github.com/" = {
          insteadOf = [
            "gh:"
            "github:"
          ];
        };
      };
    };
    includes = [
      { path = "~/.config/git/local.d/gitconfig"; } # Local ad-hoc overrides for git config
    ];
  };
}
# Git:1 ends here
