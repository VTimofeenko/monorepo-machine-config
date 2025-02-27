/**
  Assembles the pieces of config into importable form.

  This implementation allows individual files to control what aspects of the corresponding module they generate.
*/
{ pkgs, lib, self, ... }:
let
  modList =
    ./components
    |> lib.fileset.toList
    |> lib.filter (lib.hasSuffix ".nix")
    |> map (
      it:
      let
        imported = import it;
      in
      if lib.isFunction imported then imported { inherit pkgs lib self; } else imported
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
