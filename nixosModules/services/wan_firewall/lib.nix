{ localLib, ... }:
{
  pluckConcat = field: target: builtins.concatStringsSep ", " (localLib.pluck field target);
}
