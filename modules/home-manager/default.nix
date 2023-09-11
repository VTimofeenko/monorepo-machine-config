# [[file:../../new_project.org::*homeConfigurations default.nix][homeConfigurations default.nix:1]]
{ ... }:
{
  imports = [
    ./home.nix
    ./kitty # (ref:kitty-hm-import)
    ./zathura # (ref:zathura-hm-import)
    ./git.nix # (ref:git-hm-import)
    ./packages.nix # (ref:packages-hm-import)
    ./media.nix # (ref:media-hm-import)
  ];
}
# homeConfigurations default.nix:1 ends here
