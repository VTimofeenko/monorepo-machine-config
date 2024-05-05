{
  lib,
  self,
  deploy-rs,
  nixpkgs,
  docspell-flake,
  ...
}:
{
  # Wrapper around pkgs.lib.nixosSystem that adds the common modules
  mkSystem =
    {
      hostData,
      specialArgs,
      data-flake,
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
          self.overlays.homelab
          docspell-flake.overlays.default # Docspell commands rely on pkgs.docspell-joex, needs overlay
        ];
      };
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
            ]
            ++ (map (
              module: ../nixosModules/services + "/${module}"
            ) data-flake.data.hosts.all.${hostName}.modulesAt.public) # NOTE: Needs default.nix in the service directory
          ;
        }
      ];
      specialArgs = specialArgs // {
        localLib = import ../nixosModules/localLib { inherit lib; };
      }; # nixos-hardware is passed this way
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
    { nodeName, system }:
    let
      # This will reuse NixOS binary cache for deploy-rs building instead of building the package locally
      pkgs = import nixpkgs { inherit system; };
      deployPkgs = import nixpkgs {
        inherit system;
        overlays = [
          deploy-rs.overlay
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
      hostname = nodeName + ".mgmt.home.arpa"; # TODO: Make this more generic
      sshUser = "root";
      profiles.system = {
        user = "root";
        path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.${nodeName};
      };
    };
}
