/**
  Assembles the package configuration
*/
{ pkgs, lib, self, ... }:
let
  processFn =
    _: x:
    x
    |> lib.toList
    |> map lib.fileset.toList
    |> lib.flatten
    |> (map (it: import it { inherit pkgs self; }))
    # Maybe: validate that there are no odd attrs in the elements of the list
    # Adjust to expected output
    |> (it: {
      # Get either "plugin" attr or "plugins"
      plugins = (it |> builtins.catAttrs "plugin") ++ (it |> builtins.catAttrs "plugins" |> lib.flatten);
      initLua = it |> builtins.catAttrs "config" |> lib.concatStringsSep "\n";
    });
in
{
  min = ./minimal;
  std = [
    ./minimal
    ./standard
  ];
}
|> builtins.mapAttrs processFn
