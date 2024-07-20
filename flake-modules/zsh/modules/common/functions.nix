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

  spacer-unbuf = {
    description = "launch command in unbuffer, piping into spacer. Preserves colors.";
    text = # bash
      ''${pkgs.expect}/bin/unbuffer "$@" | ${pkgs.lib.getExe pkgs.spacer}'';
  };

  ad-nauseam = {
    description = "Repeat last command by every press of Return";
    text = # bash
      ''while true; do read && !!; done'';
  };
}
