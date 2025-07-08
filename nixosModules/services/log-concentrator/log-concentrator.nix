{ lib, data-flake, ... }:
{
  imports = lib.localLib.mkImportsFromDir ./functional ++ [
    data-flake.serviceModules.log-concentrator.module # import the private mixin
  ];

  services.vector.enable = true;
}
