/**
  Assembles the pieces of config into importable form.

  This implementation allows individual files to control what aspects of the corresponding module they generate.
*/
{ pkgs, lib, ... }:
let
  modList =
    ./components
    |> lib.fileset.toList
    |> map (
      it:
      let
        imported = import it;
      in
      if lib.isFunction imported then imported { inherit pkgs lib; } else imported
    );
in
{
  homeManagerModule = {
    imports = modList |> map (builtins.getAttr "homeManagerModule");
  };

  nixosModule = {
    imports = modList |> map (builtins.getAttr "nixosModule");
  };
}
