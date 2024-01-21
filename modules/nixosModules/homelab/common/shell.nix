# Configures shell for root user
{ pkgs
, ...
}:
{
  users.users.root.shell = pkgs.zsh;
  environment.systemPackages = [ pkgs.neovim ]; # Already declared as default by my zsh module
}
