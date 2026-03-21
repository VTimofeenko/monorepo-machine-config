{
  description = "A very basic flake";

  inputs = {
    base.url = "..";
    nixpkgs.follows = "base/nixpkgs";
    nixpkgs-unstable.follows = "base/nixpkgs-unstable";
    flake-parts.follows = "base/flake-parts";

    # data-flake.url = "git+ssh://gitea@gitea.srv.vtimofeenko.com/spacecadet/private-data-flake.git"; # REMOTE_SRC
    data-flake.url = "path:///home/spacecadet/code/private-data-flake"; # LOCAL_SRC

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    impermanence.url = "github:nix-community/impermanence";
    deploy-rs.follows = "base/deploy-rs";
    devshell.follows = "base/devshell";

    wg-namespace-flake = {
      url = "github:VTimofeenko/wg-namespace-flake";
    };

    private-modules = {
      # url = "git+ssh://gitea@gitea.srv.vtimofeenko.com/spacecadet/private-modules.git"; # REMOTE_SRC
      url = "path:///home/spacecadet/code/private-modules"; # LOCAL_SRC
      inputs.data-flake.follows = "data-flake";
    };
  };

  outputs =
    inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { withSystem, ... }:
      let
        inherit (inputs.base.lib) flakeModuleLoader;
        inherit (inputs.nixpkgs) lib;
      in
      {
        imports = [
          inputs.devshell.flakeModule
          inputs.base.flake-modules.devShellCmds
        ]
        ++ (flakeModuleLoader {
          dir = ./flake-modules;
          inherit self withSystem lib;
          debug = true;
        });
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        perSystem =
          { ... }:
          {
            devshellCmds.deployment = {
              enable = true;
              useDeployRs = true;
              localDeployment = true;
              desktopNotifications = true;
            };

            devshells.default = import ./devshell;
          };
        flake =
          let
            hosts = [
              "sodium"
              "lithium"
              "actinium"
              "cerium"
              "lanthanum"
              "oxygen"
              "hydrogen"
              "helium"
            ]; # TODO: auto-generate this from data

            # Merge library
            mergeLib = import ./lib/merge-manifests.nix {
              lib = lib.extend (
                lib.composeManyExtensions [
                  # There is no "Own" here, but this is useful so a `lib` with `homelab` functions is passed to the `serviceManifests`
                  (_: _: { homelab = inputs.data-flake.lib.homelab |> lib.flip builtins.removeAttrs [ "_mkOwnFuncs" ]; })
                ]
              );
            };

            # Discover public manifests (unevaluated NixOS modules)
            publicServices = self.lib.discoverModules ./services "service";

            # Get private manifests (unevaluated NixOS modules)
            privateServices = inputs.private-modules.serviceModules or { };

            # Merge and evaluate to produce final manifests with auto-assembled .default
            mergedServices = mergeLib.mergeServiceManifests publicServices privateServices;
          in
          {
            nixosConfigurations = lib.genAttrs hosts (
              hostName:
              self.lib.mkHost {
                inherit hostName;
                debug = true;
              }
            );

            deploy.nodes = lib.genAttrs hosts (
              nodeName:
              self.lib.mkDeployRsNode {
                inherit nodeName;
                system = inputs.data-flake.data.hosts.all.${nodeName}.system;
              }
            );

            # Export merged, evaluated manifests
            serviceModules = mergedServices;

            traitModules = self.lib.discoverModules ./traits "trait";

            lib = import ./flake-lib.nix { inherit lib self; };

            # Passthrough data-flake data for easy discovery
            data = inputs.data-flake.data;
          };
      }
    );
}
