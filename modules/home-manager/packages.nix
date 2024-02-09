# [[file:../../new_project.org::*Home-packages][Home-packages:1]]
{ pkgs, ... }:
{
  home.packages = builtins.attrValues { inherit (pkgs) calibre; };
}
# Home-packages:1 ends here
