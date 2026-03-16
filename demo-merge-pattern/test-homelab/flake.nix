{
  description = "Test homelab flake with manifest merging";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    test-private-modules.url = "path:../test-private-modules";
  };

  outputs = { self, nixpkgs, test-private-modules, ... }:
    let
      lib = nixpkgs.lib;

      # Simple discovery - imports manifest.nix files as modules (unevaluated)
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

      # Import merge logic
      mergeLib = import ./lib/merge-manifests.nix { inherit lib; };

      # Discover public manifests (unevaluated)
      publicServices = discoverModules ./services;

      # Get private manifests (unevaluated)
      privateServices = test-private-modules.serviceModules or {};

      # Merge and evaluate to fixed-point attrsets
      mergedServices = mergeLib.mergeServiceManifests publicServices privateServices;

    in
    {
      # Export merged, evaluated manifests as fixed-point attrsets
      # Consumers (SSL proxy, Prometheus, etc.) can use these directly
      serviceModules = mergedServices;

      # Also export public-only for debug tracking in mkHost
      publicServiceModules = publicServices;

      # Debug output
      lib.debug = {
        publicServiceNames = builtins.attrNames publicServices;
        privateServiceNames = builtins.attrNames privateServices;
        mergedServiceNames = builtins.attrNames mergedServices;

        # Show an example merged manifest
        exampleMerged = mergedServices.service-b or null;
      };
    };
}
