/**
  Functions that operate on flake itself.
*/
{ lib, self, ... }:
let
  inherit (self.inputs) data-flake nixpkgs;
in
rec {
  /**
    Extends `lib` with `lib.homelab` bound to a specific hostname and
    `lib.localLib`. Used for both regular hosts and microvm guests.
  */
  mkExtendedLib =
    hostName:
    lib.extend (
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
              inherit getManifest getManifests getSrvLib;
            };
        })
        /**
          Adds my custom functions.
          TODO: Review callsites, probably not needed as much
        */
        (_: _: { localLib = import ./lib/local-lib.nix { inherit lib; }; })
      ]
    );

  mkHost =
    {
      hostName,
      extraModules ? [ ],
      debug ? false,
    }:
    let
      inherit (self) inputs;
      inherit (builtins) trace;

      dbg = label: val: if debug then trace "[mkHost:${hostName}] ${label}" val else val;

      hostData = data-flake.data.hosts.all.${hostName};

      extendedLib = mkExtendedLib hostName;

      resolveService =
        serviceName:
        let
          serviceData = data-flake.data.services.all.${serviceName};
          moduleName = serviceData.moduleName or null;
          # Check raw sources to determine provenance (for debug logging)
          hasPublic =
            moduleName != null
            && !serviceData.sideEffectOnly
            && builtins.pathExists (./services + "/${moduleName}");
          hasPrivate =
            moduleName != null
            && !serviceData.sideEffectOnly
            && inputs.private-modules.serviceModules ? ${moduleName};
          hasMerged =
            moduleName != null && !serviceData.sideEffectOnly && self.serviceModules ? ${moduleName};
        in
        if moduleName == null || serviceData.sideEffectOnly then
          [ ]
          |> dbg "service ${serviceName} (moduleName=${toString moduleName}) is a stub or has no moduleName"
        else
          let
            # Log provenance for debugging (before accessing modules to ensure traces fire)
            loggedPublic =
              if hasPublic then dbg "service ${serviceName} -> ${moduleName} (public)" hasPublic else hasPublic;
            loggedPrivate =
              if hasPrivate then
                dbg "service ${serviceName} -> ${moduleName} (private)" hasPrivate
              else
                hasPrivate;

            # Access the merged result (which already combines public + private)
            # `self.serviceModules` contains the output of `mergeServiceManifests`
            allModules =
              if hasMerged then
                # Force evaluation of log variables, then return modules
                builtins.seq loggedPublic (builtins.seq loggedPrivate self.serviceModules.${moduleName}.default)
              else
                [ ];
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
        if traitData.sideEffectOnly then
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

      # Secret modules from private-modules — includes agenix module, `age-rekey`
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
        inputs.base.nixosModules.prometheus-ssl-exporter
        inputs.base.nixosModules.frigate-notify
        { programs.myNeovim.enable = true; }
      ];

      # These modules are side-effect free by convention
      privateModules = inputs.private-modules.nixosModules |> builtins.attrValues;

      # Microvms hosted on this machine (empty for non-hypervisor hosts).
      # Infrastructure (macvtap, filesystems) is handled by the microvm-host trait.
      # This only assembles the guest NixOS config (specialArgs + imports).
      hostedMicrovms = data-flake.lib.homelab.getMicrovms hostName;

      /**
        Produces a NixOS module that wires one microvm's guest config into the host.

        The host-side infrastructure (macvtap, filesystems) is handled by the
        `microvm-host` trait. This function only sets specialArgs and config.imports
        for the guest, using the same service/trait/secret resolution as mkHost.
      */
      mkMicroVMHostModule =
        microvmName:
        let
          microvmData = data-flake.data.hosts.all.${microvmName};
          microvmServices = microvmData.servicesAt |> lib.concatMap resolveService;
          microvmTraits = (microvmData.traitsAt or [ ]) |> lib.concatMap resolveTrait;
          microvmSecrets =
            let
              has = inputs.private-modules.secretModules ? ${microvmName};
            in
            lib.optional has inputs.private-modules.secretModules.${microvmName};
          microvmMem = microvmData.settings.mem or null;
        in
        {
          microvm.vms.${microvmName} = {
            # lib bound to the microvm's identity; inputs for trait modules (e.g. impermanence)
            specialArgs.lib = mkExtendedLib microvmName;
            specialArgs.inputs = inputs;

            config.imports =
              privateModules
              ++ microvmServices
              ++ microvmTraits # includes microvm-guest (infra + impermanence + management + network)
              ++ microvmSecrets
              ++ lib.optionals (microvmMem != null) [ { microvm.mem = microvmMem; } ];
          };
        };

      microvmHostModules = hostedMicrovms |> map mkMicroVMHostModule;

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
        { networking.hostName = hostName; }
      ]
      ++ lib.optionals (builtins.pathExists (./hosts + "/${hostName}/configuration")) [
        (./hosts + "/${hostName}/configuration")
      ]
      ++ baseFlakeModules
      ++ serviceModulesForHost
      ++ traitModulesForHost
      ++ privateModules
      ++ secretModulesForHost
      ++ microvmHostModules
      ++ extraModules;

      specialArgs = {
        inherit inputs self;
        pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${hostData.system};
      };
    };

  /**
    Returns attrset in format expected by `deploy-rs`.
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

  /**
    Returns all manifests. Easier to pass around as `lib` extension instead of `self`.
  */
  getManifests = self.serviceModules;

  /**
    Shortcut to get a service's `srvLib`
  */
  getSrvLib = serviceName: serviceName |> getManifest |> builtins.getAttr "srvLib";

  /**
    Pass `homelab` through
  */
  homelab = builtins.removeAttrs data-flake.lib.homelab [ "_mkOwnFuncs" ];

}
