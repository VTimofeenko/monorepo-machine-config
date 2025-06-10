{
  lib,
  self,
  deploy-rs,
  nixpkgs,
  ...
}:
{
  # Wrapper around pkgs.lib.nixosSystem that adds the common modules
  mkSystem =
    {
      hostData,
      specialArgs,
      data-flake,
      nur,
    }:
    let
      inherit (hostData) hostName;
    in
    lib.nixosSystem {
      inherit (hostData) system;
      # NOTE: `pkgs` instance is configured >>HERE<<
      pkgs = import nixpkgs {
        inherit (hostData) system;
        config = {
          allowUnfree = true;
          nvidia.acceptLicense = true;
        };
        overlays = [
          # docspell-flake.overlays.default # Docspell commands rely on pkgs.docspell-joex, needs overlay
        ];
      };

      # Extend standard lib argument to have my homelab data
      lib =
        let
          inherit (data-flake.lib) homelab;

          homelabExt =
            _: _:
            lib.pipe { inherit homelab; } [
              (lib.flip builtins.removeAttrs [ "_mkOwnFuncs" ]) # Remove generating func
              (lib.recursiveUpdate { homelab = homelab._mkOwnFuncs hostName; }) # Bind get functions to hostname, producing getOwn* functions
            ];

          localLibExt = _: _: { localLib = import ./locallib.nix { inherit lib; }; };
        in
        lib.extend (
          lib.composeManyExtensions [
            homelabExt
            localLibExt
          ]
        );

      modules = [
        (./. + "/../nixosConfigurations/${hostName}/configuration") # every host has "configuration" directory. /. converts it to path
        {
          networking = {
            inherit hostName;
          };
        }
        {
          imports =
            [
              ../modules/nixOS/homelab/common

              data-flake.nixosModules.${hostName}

              specialArgs.selfModules.my-theme
              specialArgs.selfModules.zsh
              specialArgs.selfModules.tmux
              specialArgs.selfModules.vim
              {
                programs.myNeovim.enable = true;
              }
            ]
            # Per-host overrides
            # TODO: make more generic
            ++ (lib.optionals (hostData.hostName == "uranium") [
              nur.modules.nixos.default
              ../modules
            ])
            ++ (lib.optionals (hostData.hostName == "neon") [ self.inputs.microvm.nixosModules.host ])
            ++ (map (
              module: ../nixosModules/services + "/${module}"
            ) data-flake.data.hosts.all.${hostName}.modulesAt.public) # NOTE: Needs default.nix in the service directory
          ;
        }
      ];
      specialArgs = specialArgs // {
        pkgs-unstable = self.inputs.nixpkgs-unstable.legacyPackages.${hostData.system};
      };
    };
  /*
    Returns attrset in format expected by deploy-rs.

    Example:
    mkDeployRsNode {nodeName = "foo-node"; system = "x86_64-linux"; }: {
    profiles.system = {
      user = "root";
      path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.foo-node;
    };
    }
  */
  mkDeployRsNode =
    {
      nodeName,
      system,
      data-flake,
    }:
    let
      # This will reuse NixOS binary cache for deploy-rs building instead of building the package locally
      pkgs = import nixpkgs { inherit system; };
      deployPkgs = import nixpkgs {
        inherit system;
        overlays = [
          deploy-rs.overlays.default
          (_: super: {
            deploy-rs = {
              inherit (pkgs) deploy-rs;
              inherit (super.deploy-rs) lib;
            };
          })
        ];
      };
    in
    {
      hostname = "${nodeName}.${data-flake.data.networks.mgmt.domain}";
      sshUser = "root";
      profiles.system = {
        user = "root";
        path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.${nodeName};
      };
    };
}
