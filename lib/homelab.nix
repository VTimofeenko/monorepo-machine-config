{ lib
, self
, deploy-rs
, nixpkgs
, ...
}:
{
  /*
    Wrapper around pkgs.lib.nixosSystem that adds the common modules
  */
  mkSystem = hostData:
    let
      inherit (hostData) hostName;
    in
    lib.nixosSystem rec {
      inherit (hostData) system;
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          self.overlays.default
        ];
      };
      modules = [
        (./. + "/../hosts/${hostName}/configuration") # every host has "configuration" directory. /. converts it to path
        { networking = { inherit hostName; }; }
        {
          imports = [
            ../modules/common/dump.nix
            ../modules/common/nix.nix
            ../modules/common/time.nix
            ../modules/common/packages.nix
            ../modules/common/sshd.nix
            ../modules/common/firewall.nix
            ../modules/common/shell.nix
          ];
        }
      ]
        # TODO: add modules from data flake
        # TODO: Add modules from lib

        # ++
        # (localLib.getModules hostName); # This retrieves modules for the services running at that host
        # specialArgs = {
        #   inherit localLib netConfig srvConfig hostConfig globalSettings my-config-flake;
        #   inherit serviceSecrets;

        #   # inherit notNftLib;
        # };
      ;
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
  mkDeployRsNode = { nodeName, system }: {
    hostname = "192.168.1.1"; # TODO: Replace this after mgmt on 1.1 is up
    sshUser = "root";
    profiles.system = {
      user = "root";
      path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.${nodeName};
    };
  };
}
