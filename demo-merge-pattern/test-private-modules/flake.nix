{
  description = "Test private modules flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      lib = nixpkgs.lib;

      # Simple discovery - just imports manifest.nix files as modules (functions)
      # Does NOT evaluate them - returns unevaluated functions
      discoverModules = dir:
        let
          entries = builtins.readDir dir;
        in
        builtins.foldl' (acc: name:
          if entries.${name} == "directory" && builtins.pathExists (dir + "/${name}/manifest.nix")
          then
            acc // {
              ${name} = import (dir + "/${name}/manifest.nix");
            }
          else
            acc
        ) {} (builtins.attrNames entries);
    in
    {
      # Export unevaluated manifest modules
      serviceModules = discoverModules ./services;

      # For debugging - show what we export
      lib.debug = {
        serviceNames = builtins.attrNames self.serviceModules;
      };
    };
}
