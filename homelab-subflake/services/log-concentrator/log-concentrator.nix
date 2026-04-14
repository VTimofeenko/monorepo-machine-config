{ lib, ... }:
{
  imports = lib.localLib.mkImportsFromDir ./functional;

  services.vector.enable = true;
}
