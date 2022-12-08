{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    lazygit
    git-crypt
  ];
  programs.git = {
    enable = true;
    config = {
      user = {
        name = "Vladimir Timofeenko";
        email = "id@vtimofeenko.com";
      };
      alias = {
        ci = "commit";
        st = "status";
        co = "checkout";
        rv = "remote --verbose"
          unstage = "reset HEAD --";
      };
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
