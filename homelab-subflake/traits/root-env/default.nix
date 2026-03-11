{ pkgs, ... }:
{
  users.users.root.shell = pkgs.zsh;
  environment.systemPackages = [ pkgs.git ];
  programs.ripgrep = {
    enable = true;
    arguments = [
      "--smart-case" # lowercase = ignorecase
      "--follow" # need symlinks often
    ];
  };
}
