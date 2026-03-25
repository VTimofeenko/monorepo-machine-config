/**
  DNS Test VM Configuration

  Creates a test VM that runs only `auth-dns` and `dns` services.
  Uses data-flake's `mkCustom` to extend the data with test VM configuration.

  Usage:
  ```
  nix run .#nixosConfigurations.dns-test-vm.config.system.build.vm
  ```
*/
{
  inputs,
  self,
  lib,
  ...
}:
let
  # Extended data with test VM
  testData = import ./test-data.nix { data-flake = inputs.data-flake; };

  # Create custom homelab lib with test data
  customHomelabLib = inputs.data-flake.lib.homelab.mkCustom testData;

  hostName = "dns-test-vm";

  # Build extended lib that `mkHost` expects
  extendedLib = lib.extend (
    lib.composeManyExtensions [
      # Replace homelab lib with our custom one that has test data
      # Include both base functions and host-specific "Own" functions
      (_: _: {
        homelab =
          customHomelabLib
          // customHomelabLib._mkOwnFuncs hostName
          // {
            inherit (self.lib) getManifest getManifests;
          };
      })
      # Add local lib functions
      (_: _: { localLib = import ../lib/local-lib.nix { inherit lib; }; })
    ]
  );

  hostData = testData.hosts.all.${hostName};

  # Resolve services for test VM (same logic as `mkHost`)
  resolveService =
    serviceName:
    let
      serviceData = testData.services.all.${serviceName};
      moduleName = serviceData.moduleName or null;
      fromPublic = moduleName != null && moduleName != "stub" && self.serviceModules ? ${moduleName};
    in
    if moduleName == null || moduleName == "stub" then
      [ ]
    else if fromPublic then
      self.serviceModules.${moduleName}.default
    else
      [ ];

  serviceModules = hostData.servicesAt |> lib.concatMap resolveService;

  # Resolve traits (minimal for test VM)
  resolveTrait =
    traitName: if self.traitModules ? ${traitName} then [ self.traitModules.${traitName} ] else [ ];

  traitModules = (hostData.traitsAt or [ ]) |> lib.concatMap resolveTrait;

  # Base modules from base flake
  baseFlakeModules = [
    inputs.base.nixosModules.zsh
    inputs.base.nixosModules.tmux
    inputs.base.nixosModules.vim
    inputs.base.nixosModules.my-theme
    { programs.myNeovim.enable = true; }
  ];

in
lib.nixosSystem {
  inherit (hostData) system;
  lib = extendedLib;
  pkgs = import inputs.nixpkgs {
    inherit (hostData) system;
    config.allowUnfree = true;
    overlays = [ inputs.base.overlays.default ];
  };
  modules = [
    ../hosts/${hostName}/configuration
    { networking.hostName = hostName; }

    # Enable VM building with serial console (no graphical window)
    {
      virtualisation.vmVariant = {
        virtualisation = {
          memorySize = 2048;
          cores = 2;
          graphics = false;
          qemu.options = [ "-nographic" ];
        };
      };
    }
  ]
  ++ baseFlakeModules
  ++ serviceModules
  ++ traitModules;

  specialArgs = {
    inherit inputs self;
    pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${hostData.system};
  };
}
