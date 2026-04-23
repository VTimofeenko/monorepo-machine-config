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

  /**
    Resolves all NixOS modules for a given host: services, traits, secrets,
    base flake modules, and private modules. Used by both `mkHost` (for real
    hosts) and `mkMicroVMHostModule` (for inline microvm guest configs).

    Returns an attrset with:
      - `extendedLib`: lib extended with homelab + localLib bound to hostName
      - `hostData`: raw host data from data-flake
      - `pkgs`: nixpkgs instance with overlays applied
      - `modules`: all resolved NixOS modules (base + services + traits + private + secrets)
      - `specialArgs`: standard specialArgs for nixosSystem / microvm.vms
      - `dbg`: trace helper (no-ops when debug = false)
  */
  mkHostConfig =
    {
      hostName,
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
            loggedPublic =
              if hasPublic then dbg "service ${serviceName} -> ${moduleName} (public)" hasPublic else hasPublic;
            loggedPrivate =
              if hasPrivate then
                dbg "service ${serviceName} -> ${moduleName} (private)" hasPrivate
              else
                hasPrivate;

            allModules =
              if hasMerged then
                builtins.seq loggedPublic (builtins.seq loggedPrivate self.serviceModules.${moduleName}.default)
              else
                [ ];
          in
          lib.warnIf (lib.length allModules == 0)
            "service: ${serviceName} (moduleName: ${moduleName}) could not be resolved to an implementation!"
            allModules;

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
            |> (
              it:
              lib.warnIf (lib.length it == 0) "trait: ${traitName} could not be resolved to an implementation!" it
            )
          );

      serviceModules = hostData.servicesAt |> lib.concatMap resolveService;
      traitModules = (hostData.traitsAt or [ ]) |> lib.concatMap resolveTrait;

      secretModules =
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
        inputs.base.nixosModules.fava
        { programs.myNeovim.enable = true; }
      ];

      # These modules are side-effect free by convention
      privateModules = inputs.private-modules.nixosModules |> builtins.attrValues;

      pkgs = import nixpkgs {
        inherit (hostData) system;
        config.allowUnfree = true;
        config.nvidia.acceptLicense = true;
        overlays = [
          inputs.base.overlays.default
          inputs.private-modules.overlays.default
        ];
      };
    in
    {
      inherit
        extendedLib
        hostData
        pkgs
        dbg
        ;
      modules = baseFlakeModules ++ serviceModules ++ traitModules ++ privateModules ++ secretModules;
      specialArgs = {
        inherit inputs self;
        pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${hostData.system};
      };
    };

  mkHost =
    {
      hostName,
      extraModules ? [ ],
      debug ? false,
    }:
    let
      cfg = mkHostConfig { inherit hostName debug; };
      hostedMicrovms = data-flake.lib.homelab.getMicrovms hostName;
      microvmHostModules = hostedMicrovms |> map mkMicroVMHostModule;
    in
    cfg.dbg "system=${cfg.hostData.system}" lib.nixosSystem {
      inherit (cfg.hostData) system;
      lib = cfg.extendedLib;
      inherit (cfg) pkgs specialArgs;
      modules = [
        { networking.hostName = hostName; }
      ]
      ++ lib.optionals (builtins.pathExists (./hosts + "/${hostName}/configuration")) [
        (./hosts + "/${hostName}/configuration")
      ]
      ++ cfg.modules
      ++ microvmHostModules
      ++ extraModules;
    };

  /**
    Produces a NixOS module that wires one microvm's guest config into the host.

    The host-side infrastructure (macvtap, filesystems) is handled by the
    `microvm-host` trait. This function only sets specialArgs and config.imports
    for the guest, using the same service/trait/secret resolution as mkHost.
  */
  mkMicroVMHostModule =
    microvmName:
    let
      cfg = mkHostConfig { hostName = microvmName; };
      microvmMem = cfg.hostData.settings.mem or null;
    in
    {
      microvm.vms.${microvmName} = {
        specialArgs = cfg.specialArgs // {
          lib = cfg.extendedLib;
        };
        config.imports =
          cfg.modules ++ lib.optionals (microvmMem != null) [ { microvm.mem = microvmMem; } ];
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
