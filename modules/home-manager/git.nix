# [[file:../../new_project.org::*Git][Git:1]]
{ pkgs, ... }: {
  home.packages = builtins.attrValues {
    inherit (pkgs) git lazygit git-crypt;
  };
  programs.git = {
    enable = true;
    aliases = {
      ci = "commit";
      st = "status";
      co = "checkout";
      rv = "remote --verbose";
      unstage = "reset HEAD --";
    };
    userEmail = "id@vtimofeenko.com";
    userName = "Vladimir Timofeenko";
    ignores = [
      # Vim swap files
      "*.swp"
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
  };
}
# Git:1 ends here
