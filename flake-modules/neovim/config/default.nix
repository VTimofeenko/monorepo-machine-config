/**
  Assembles the package configuration
*/
{
  pkgs,
  lib,
  self,
  ...
}:
let
  pkgs-unstable = self.inputs.nixpkgs-unstable.legacyPackages.${pkgs.system};
  processFn =
    _: x:
    x
    |> lib.toList
    |> map lib.fileset.toList
    |> lib.flatten
    |> (map (
      it:
      import it {
        inherit
          pkgs
          lib
          self
          pkgs-unstable
          ;
      }
    ))
    # Remove explicitly disabled plugins (i.e. `enabled` attr has to be present and false)
    |> lib.filter (it: it.enabled or true)
    # Maybe: validate that there are no odd attrs in the elements of the list
    # Adjust to expected output
    |> (it: {
      # Get either "plugin" attr or "plugins"
      plugins = (it |> builtins.catAttrs "plugin") ++ (it |> builtins.catAttrs "plugins" |> lib.flatten);
      initLua = it |> builtins.catAttrs "config" |> lib.flatten |> lib.concatStringsSep "\n";
      packages = it |> builtins.catAttrs "extraPackages" |> lib.flatten;
    });
in
{
  min = ./minimal;
  std = [
    ./minimal
    ./standard
  ];
  max = [
    ./minimal
    ./standard
    ./max
  ];
}
|> builtins.mapAttrs processFn
