/**
  Assembles the package configuration
*/
{ pkgs, lib, ... }:
{
  min =
    ./minimal
    |> lib.fileset.toList
    |> (map (it: import it { inherit pkgs; }))
    # Adjust to expected output
    |> (it: {
      plugins = it |> builtins.catAttrs "plugin";
    });
}
