# NOTE:  The diagnostics mean LSPs are working

{ pkgs, lib, ... }:
let
  foo = "bar";
  foz = {
    someLongAttribute = null;
  };

  # Try out code action flatten
  flattenMe = {
    inner = null;
  };

  # Try out code action "pack"
  packMe.inner = null;
  packMe.otherInner = null;
in
{
  # Thiiiis is a typo. Harper should catch it!
  # Remove this line and re-type it. "programs.git.package" and "pkgs.git" should be auto-completed
  programs.git.package = pkgs.git;

  # Next line contains the word `hmts`. While "hmts" is a typo, harper should be smart enough.
  # This attribute shows `hmts` injecting a different language into a nix string highlight
  programs.zsh.completionInit =
    # sh
    ''
      export FOO="BAR"
    '';
}
