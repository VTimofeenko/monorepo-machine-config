/**
  Functions that operate on flake itself.
*/
{ lib, self, ... }:
let
  inherit (builtins) filter isAttrs;
  inherit (lib) flatten optional;

  /**
    Auto-assembles a manifest's `default` attribute from its component fields.

    Takes a manifest attrset and returns the same attrset with `default` added.
    The `default` list contains all modules that should be imported for this service.

    Auto-assembly rules:
    1. Always include `module` if present
    2. Include `firewall` if present (future: auto-generate from endpoints)
    3. Collect all `impl` fields from observability.{metrics, logging, probes, alerts}
    4. Include `backups.impl` if present (future: auto-generate from backups data)
    5. Include `storage.impl` if present

    Example:
    ```
      mkManifest {
        module = ./service.nix;
        firewall = ./firewall.nix;
        observability.metrics.impl = ./metrics.nix;
        backups.paths = [ "/var/lib/svc" ];
      }
      =>
      {
        module = ./service.nix;
        firewall = ./firewall.nix;
        observability.metrics.impl = ./metrics.nix;
        backups.paths = [ "/var/lib/svc" ];
        default = [ ./service.nix ./firewall.nix ./metrics.nix ];
      }
    ```
  */
  mkManifest = manifest:
    let
      # Helper to extract impl from an attrset if it exists
      extractImpl = attr: optional (isAttrs attr && attr ? impl) attr.impl;

      # Gather observability impls
      observabilityImpls =
        if manifest ? observability then
          flatten [
            (extractImpl (manifest.observability.metrics or {}))
            (extractImpl (manifest.observability.logging or {}))
            (extractImpl (manifest.observability.probes or {}))
            (extractImpl (manifest.observability.alerts or {}))
          ]
        else
          [];

      # Auto-generate firewall if not provided but endpoints exist
      firewallModule =
        if manifest ? firewall then
          manifest.firewall
        else if manifest ? endpoints then
          { lib, self, ... }:
          let
            # Extract all ports from endpoints
            ports = lib.mapAttrsToList (_: ep: ep.port) manifest.endpoints
              |> lib.unique;
          in
          {
            imports = [
              (self.serviceModules.ssl-proxy.srvLib.mkBackboneInnerFirewallRules {
                inherit lib;
                inherit ports;
              })
            ];
          }
        else
          null;

      # Assemble default from all components
      defaultModules = flatten [
        (optional (manifest ? module) manifest.module)
        (optional (firewallModule != null) firewallModule)
        observabilityImpls
        (extractImpl (manifest.backups or {}))
        (extractImpl (manifest.storage or {}))
      ]
      # Filter out empty sets and nulls
      |> filter (v: v != {} && v != null);

    in
    manifest // { default = defaultModules; };

in
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
          (_: _: { localLib = import ./lib/local-lib.nix { inherit lib; }; })
        ]
      );

      resolveService =
        moduleName:
        let
          serviceData = data-flake.data.services.all.${moduleName};
          fromPublic = self.serviceModules ? ${moduleName};
          fromPrivate = inputs.private-modules.serviceModules ? ${moduleName};
        in
        if serviceData.moduleName == "stub" then
          [ ] |> dbg "service ${moduleName} is a stub"
        else
          (
            lib.optionals fromPublic (
              dbg "service ${moduleName} (public)" self.serviceModules.${moduleName}.default
            )
            ++ lib.optionals fromPrivate (
              dbg "service ${moduleName} (private)" inputs.private-modules.serviceModules.${moduleName}.default
            )
            |> (
              it:
              lib.warnIf (
                lib.length it == 0
              ) "service: ${moduleName} could not be resolved to an implementation!" it
            )
          );

      serviceModulesForHost =
        hostData.servicesAt
        |> map (name: data-flake.data.services.all.${name})
        |> lib.filter (svc: svc.moduleName or null != null)
        |> lib.concatMap (svc: resolveService svc.moduleName);

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
        ((
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
          ));

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

  # Export mkManifest for use in manifests
  inherit mkManifest;

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
          name:
            let
              imported = import (dir + "/${name}/${fileMarker.service}");
              # If imported is a function, call it with serviceName
              rawManifest = if builtins.isFunction imported then imported name else imported;
              # Apply mkManifest to auto-assemble default if not already present
              manifest = if rawManifest ? default then rawManifest else mkManifest rawManifest;
            in
            manifest
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
