/**
  Functions that operate on flake itself.
*/
{ lib, self, ... }:
{
  /**
    Produces a `nixosConfiguration` for a given host.
  */
  mkHost =
    {
      hostName,
      role,
      extraModules ? [ ],
      debug ? false,
    }:
    let
      inherit (self) inputs;
      inherit (inputs) data-flake nixpkgs;
      inherit (builtins) trace;

      dbg = label: val: if debug then trace "[mkHost:${hostName}] ${label}" val else val;

      hostData = data-flake.data.hosts.all.${hostName};

      extendedLib = lib.extend (
        lib.composeManyExtensions [
          /**
            Adds `lib.homelab.<functions>`.

            `_mkOwnFuncs` generates functions like `getOwnIPInNetwork`
          */
          (_: _: {
            homelab =
              builtins.removeAttrs data-flake.lib.homelab [ "_mkOwnFuncs" ]
              // data-flake.lib.homelab._mkOwnFuncs hostName;
          })
          /**
            Adds my custom functions.
            TODO: Review callsites, probably not needed as much
          */
          (_: _: { localLib = import ../lib.nix { inherit lib; }; })
        ]
      );

      resolveService =
        moduleName:
        let
          fromPublic = self.serviceModules ? ${moduleName};
          fromPrivate = inputs.private-modules.serviceModules ? ${moduleName};
        in
        lib.optionals fromPublic (dbg "service ${moduleName} (public)" self.serviceModules.${moduleName}.default)
        ++ lib.optionals fromPrivate (
          dbg "service ${moduleName} (private)" inputs.private-modules.serviceModules.${moduleName}.default
        );

      serviceModulesForHost =
        hostData.servicesAt
        |> map (name: data-flake.data.services.all.${name})
        |> lib.filter (svc: svc.moduleName or null != null)
        |> lib.concatMap (svc: resolveService svc.moduleName);

      resolveTrait =
        traitName:
        let
          fromPublic = self.traitModules ? ${traitName};
          fromPrivate = inputs.private-modules.traitModules ? ${traitName};
        in
        (
          lib.optional fromPublic (dbg "trait ${traitName} (public)" self.traitModules.${traitName})
          ++ lib.optional fromPrivate (
            dbg "trait ${traitName} (private)" inputs.private-modules.traitModules.${traitName}
          )
        )
        # This check alerts the operator if trait could not be found as an actual module.
        # Potential problems:
        # - The implementation of the trait is missing
        # - False negative detection (see `discoverModules`)
        |> (
          it:
          lib.warnIf (lib.length it == 0) "trait: ${traitName} could not be resolved to an implementation!" it
        );

      traitModulesForHost = (hostData.traitsAt or [ ]) |> lib.concatMap resolveTrait;

      # Secret modules from private-modules — includes agenix module, age.rekey
      # config, and all secret definitions for this host. Self-contained: homelab
      # does not need to know about agenix internals.
      secretModulesForHost =
        let
          has = inputs.private-modules.secretModules ? ${hostName};
        in
        lib.optional has (dbg "secrets (private-modules)" inputs.private-modules.secretModules.${hostName});

      baseFlakeModules = [
        inputs.base.nixosModules.zsh
        inputs.base.nixosModules.tmux
        inputs.base.nixosModules.vim
        inputs.base.nixosModules.my-theme
        { programs.myNeovim.enable = true; }
      ];

      clientModules = [ ../modules/de ];

    in
    dbg "role=${role}, system=${hostData.system}" lib.nixosSystem {
      inherit (hostData) system;
      lib = extendedLib;
      pkgs = import nixpkgs {
        inherit (hostData) system;
        config.allowUnfree = true;
        overlays = [ inputs.base.overlays.default ];
      };
      modules = [
        ./hosts/${hostName}/configuration
        { networking.hostName = hostName; }
      ]
      ++ baseFlakeModules
      ++ serviceModulesForHost
      ++ traitModulesForHost
      ++ secretModulesForHost
      ++ lib.optionals (role == "client") clientModules
      ++ extraModules;

      specialArgs = {
        inherit inputs self;
        pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${hostData.system};
      };
    };

  /**
    Returns attrset in format expected by deploy-rs.
  */
  mkDeployRsNode =
    { nodeName, system }:
    let
      inherit (self) inputs;
      pkgs = import inputs.nixpkgs { inherit system; };
      deployPkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          inputs.deploy-rs.overlays.default
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
      hostname = "${nodeName}.${inputs.data-flake.data.networks.mgmt.domain}";
      sshUser = "root";
      profiles.system = {
        user = "root";
        path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.${nodeName};
      };
    };

  /**
    Used to discover service modules and traits.
  */
  discoverModules =
    dir: format:
    let
      entries = builtins.readDir dir;
      fileMarker = {
        service = "manifest.nix";
        trait = "default.nix";
      };

      importEffect =
        if format == "service" then
          name: import (dir + "/${name}/${fileMarker.service}")
        else
          name: import (dir + "/${name}");
    in
    builtins.foldl' (
      acc: name:
      if
        entries.${name} == "directory" && builtins.pathExists (dir + "/${name}/${fileMarker.${format}}")
      then
        acc // { ${name} = importEffect name; }
      else
        acc
    ) { } (builtins.attrNames entries);

}
