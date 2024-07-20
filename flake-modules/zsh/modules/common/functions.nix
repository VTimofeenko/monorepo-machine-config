{ pkgs, ... }:
let
  inherit (pkgs) coreutils-full;
  dirname = "${coreutils-full}/bin/dirname";
  readlink = "${coreutils-full}/bin/readlink";
in
{
  mkcd = {
    description = "Make a directory and change there";
    text = # bash
      ''mkdir -p "$@" && cd "$@"'';
  };

  cdd = {
    description = "cd into a file's directory";
    text = # bash
      "cd $(${dirname} $1)";
  };

  cdnixpkg = {
    description = "cd into a nix store directory where a binary is";
    text = # bash
      "cd $(${dirname} $(${readlink} --canonicalize $(which $1)))";
  };

}
