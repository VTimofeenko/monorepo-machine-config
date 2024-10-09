# [[file:../../new_project.org::*homeConfigurations default.nix][homeConfigurations default.nix:1]]
{ ... }:
{
  imports = [
    ./home.nix
    ./zathura # (ref:zathura-hm-import)
    ./packages.nix # (ref:packages-hm-import)
    ./media.nix # (ref:media-hm-import)
    ./swayimg

    ../homeManager
  ];
}
# homeConfigurations default.nix:1 ends here
