{
  self,
}:
{
  /**
    Produces a module
  */
  mkModule = mode: import ./mk-module.nix { inherit self mode; };

  /**
    This function consumes a module, applies provided config and produces a package.
    This allows me to define the package generation logic in the module.
  */
  mkPackage =
    {
      pkgType,
      pkgs,
      lib,
    }:
    let
      modToEval = self.homeManagerModules.vim;
      config =
        # Grab a base module
        modToEval
        # Evaluate it
        |> (
          it:
          lib.evalModules {
            modules = [
              { _module.check = false; } # This skips some checks that can be (probably) safely bypassed
              it
            ];
            specialArgs = { inherit pkgs lib; };
          }
        )
        # Get only the config from the result
        |> builtins.getAttr "config"
        # Apply the package type to the config
        |> lib.flip lib.recursiveUpdate { programs.myNeovim.type = pkgType; };
    in
    # Treat the module as a function and apply it to get the value of the package
    # Take the module
    modToEval.imports
    # Get the function itself
    |> builtins.head
    # Apply
    |> (it: it { inherit pkgs lib config; })
    # Extract the package
    |> lib.getAttrFromPath [
      "config"
      "content"
      "programs"
      "myNeovim"
      "finalPackage"
    ];

}
