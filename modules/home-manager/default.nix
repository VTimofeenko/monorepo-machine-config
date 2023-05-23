# [[file:../../new_project.org::*homeConfigurations default.nix][homeConfigurations default.nix:1]]
{ ... }:
{
  imports = [
    ./home.nix
    ./vim # (ref:vim-hm-import)
    ./kitty # (ref:kitty-hm-import)
    ./zsh # (ref:zsh-hm-import)
    ./zathura # (ref:zathura-hm-import)
    ./git.nix # (ref:git-hm-import)
    ./packages.nix # (ref:packages-hm-import)
  ];
}
# homeConfigurations default.nix:1 ends here
