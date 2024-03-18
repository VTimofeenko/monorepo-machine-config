{
  self,
  pkgs,
  lib,
  ...
}:
let
  checks = [ ./check-dns-replies.nix ];
  inherit (lib) pipe;
in
pipe checks [
  (map (checkFile: {
    name = pipe checkFile [
      builtins.toString
      builtins.baseNameOf
      (lib.replaceStrings [ ".nix" ] [ "" ])
    ];
    value = pkgs.testers.runNixOSTest (import checkFile { inherit self; });
  }))
  builtins.listToAttrs
]
