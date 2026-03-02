# Common for both home-manager and NixOS configuration
{ self, ... }:
{
  nix = {
    settings = {
      connect-timeout = 5;
      experimental-features = "nix-command flakes pipe-operators";
      warn-dirty = false;
      download-buffer-size = 1048576000; # 1 gigabyte
    };

    registry = {
      ns.flake = self.inputs.nixpkgs-stable;
      nu.flake = self.inputs.nixpkgs-unstable;
      /**
        Something I might restore later, a set of dynamic pins:
        ```
        // lib.pipe inputs [
          (filterAttrs (_: v: (v ? _type && v._type == "flake"))) # Filter only flakes in inputs
          (mapAttrs' (a: v: nameValuePair ("pinned-" + a) { flake = v; })) # Turn them into proper entries in registry
        ];
        ```
      */
    };
  };
}
