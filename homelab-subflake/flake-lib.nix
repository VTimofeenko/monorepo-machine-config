/**
  Functions that operate on flake itself.
*/
{ lib, self, ... }:
rec {
  /**
    Produces a `nixosConfiguration` for a given host.
  */
  mkHost =
    {
      hostName,
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
              // data-flake.lib.homelab._mkOwnFuncs hostName
              // {
                inherit getManifest;
              };
          })
          /**
            Adds my custom functions.
            TODO: Review callsites, probably not needed as much
          */
          (_: _: { localLib = import ./lib/local-lib.nix { inherit lib; }; })
        ]
      );

      resolveService =
        serviceName:
        let
          serviceData = data-flake.data.services.all.${serviceName};
          moduleName = serviceData.moduleName or null;
          fromPublic = moduleName != null && moduleName != "stub" && self.serviceModules ? ${moduleName};
          fromPrivate =
            moduleName != null && moduleName != "stub" && inputs.private-modules.serviceModules ? ${moduleName};

          # Get manifest for source tracking (prefer public if both exist)
          manifest =
            if fromPublic then
              self.serviceModules.${moduleName}
            else if fromPrivate then
              inputs.private-modules.serviceModules.${moduleName}
            else
              null;

          # Determine sources from manifest metadata
          sources =
            if manifest != null && manifest ? _sources then
              if manifest._sources.hasPublic && manifest._sources.hasPrivate then
                "public+private"
              else if manifest._sources.hasPublic then
                "public"
              else
                "private"
            else if fromPublic && fromPrivate then
              "public+private"
            else if fromPublic then
              "public"
            else if fromPrivate then
              "private"
            else
              "unknown";
        in
        if moduleName == null || moduleName == "stub" then
          [ ]
          |> dbg "service ${serviceName} (moduleName=${toString moduleName}) is a stub or has no moduleName"
        else
          let
            # .default is already a list of modules, so concatenate rather than nest
            publicModules =
              if fromPublic then
                (dbg "service ${serviceName} -> ${moduleName} (public)" self.serviceModules.${moduleName}.default)
              else
                [ ];
            privateModules =
              if fromPrivate then
                (dbg "service ${serviceName} -> ${moduleName} (private)"
                  inputs.private-modules.serviceModules.${moduleName}.default
                )
              else
                [ ];
            allModules = publicModules ++ privateModules;
          in
          lib.warnIf (lib.length allModules == 0)
            "service: ${serviceName} (moduleName: ${moduleName}) could not be resolved to an implementation!"
            allModules;

      serviceModulesForHost = hostData.servicesAt |> lib.concatMap resolveService;

      resolveTrait =
        traitName:
        let
          traitData = data-flake.data.traits.all.${traitName};
          fromPublic = self.traitModules ? ${traitName};
          fromPrivate = inputs.private-modules.traitModules ? ${traitName};
        in
        if traitData.moduleName == "stub" then
          [ ] |> dbg "trait ${traitName} is a stub"
        else
          (
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
            )
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
        inputs.base.nixosModules.apprise-api # TODO: just import all once `de` is migrated
        { programs.myNeovim.enable = true; }
      ];

    in
    dbg "system=${hostData.system}" lib.nixosSystem {
      inherit (hostData) system;
      lib = extendedLib;
      pkgs = import nixpkgs {
        inherit (hostData) system;
        config.allowUnfree = true;
        config.nvidia.acceptLicense = true;
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
    Discovers service/trait modules and returns unevaluated modules.
    For services: returns NixOS modules that will be merged later.
    For traits: returns modules directly.
  */
  discoverModules =
    dir: format:
    let
      entries = builtins.readDir dir;
      fileMarker = {
        service = "manifest.nix";
        trait = "default.nix";
      };
    in
    builtins.foldl' (
      acc: name:
      if
        entries.${name} == "directory" && builtins.pathExists (dir + "/${name}/${fileMarker.${format}}")
      then
        acc // { ${name} = import (dir + "/${name}/${fileMarker.${format}}"); }
      else
        acc
    ) { } (builtins.attrNames entries);

  /**
    Returns the manifest for a given service.

    This allows service modules to access their own manifest data, making it
    easier to propagate endpoints and other configuration from the manifest
    into the service implementation.

    Example:
    ```nix
    { self, ... }:
    let
      manifest = self.lib.getManifest "web-receipt-printer";
    in
    {
      services.web-receipt-printer = {
        enable = true;
        port = manifest.endpoints.web.port;
      };
    }
    ```
  */
  getManifest = serviceName: self.serviceModules.${serviceName};

}
