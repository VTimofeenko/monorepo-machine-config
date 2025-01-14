/**
  Assembles the package configuration
*/
{ pkgs, lib, ... }:
{
  min =
    ./minimal
    |> lib.fileset.toList
    |> (map (it: import it { inherit pkgs; }))
    # Maybe: validate that there are no odd attrs in the elements of the list
    # Adjust to expected output
    |> (it: {
      # Get either "plugin" attr or "plugins"
      plugins = (it |> builtins.catAttrs "plugin") ++ (it |> builtins.catAttrs "plugins" |> lib.flatten);
      initLua = it |> builtins.catAttrs "config" |> lib.concatStringsSep "\n";

    });
}
