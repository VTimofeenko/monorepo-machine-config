{ lib, ... }:
let
  inherit (lib.localLib) pluck;
in
{
  pluckConcat = field: target: builtins.concatStringsSep ", " (pluck field target);
}
