{ pkgs, config, ... }:

{
  environment.systemPackages = [ pkgs.my_nvim ];
  environment.variables.SUDO_EDITOR = "nvim";
  environment.variables.EDITOR = "nvim";
}
