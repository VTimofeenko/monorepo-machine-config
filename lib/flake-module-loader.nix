/**
  Auto-loader for flake-modules in a flake-parts repository.

  Discovers subdirectories in `dir` and produces flake-parts modules:

    Manual (default.nix exists):

      -> `(import dir/name { inherit self withSystem lib; })`

      The module controls its own inputs and outputs.

    Auto-discovered (no default.nix):
      -> module constructed from well-known filenames:

      ```
      package.nix                  -> perSystem.packages.{name}
      packages/*.nix               -> perSystem.packages.{stem}
      app.nix                      -> perSystem.apps.{name}
      apps/*.nix                   -> perSystem.apps.{stem}
      check.nix                    -> perSystem.checks.{name}
      checks/*.nix                 -> perSystem.checks.{stem}
      nixos-module.nix             -> flake.nixosModules.{name}
      nixos-modules/*.nix          -> flake.nixosModules.{stem}
      home-manager-module.nix      -> flake.homeManagerModules.{name}
      home-manager-modules/*.nix   -> flake.homeManagerModules.{stem}
      ```

    Where: `{name}` = directory name. `{stem}` = filename without "`.nix`".

    Auto-discovered packages are automatically added to `perSystem.overlayAttrs`
    so they compose with flake-parts `easyOverlay`.

  Type: `{ dir, self, withSystem, lib, debug? } -> [ FlakePartsModule ]`
*/
{
  dir,
  self,
  withSystem,
  lib,
  debug ? false,
}:

let
  inherit (builtins)
    readDir
    pathExists
    attrNames
    filter
    trace
    ;

  args = { inherit self withSystem lib; };

  # When debug is true, trace the label and return the value unchanged.
  # When debug is false, it's effectively lib.id.
  dbg = label: val: if debug then trace "[flake-module-loader] ${label}" val else val;

  # ── Helpers ────────────────────────────────────────────────────────

  # List .nix files in a directory as [ { stem, path } ].
  nixFilesIn =
    dirPath:
    if pathExists dirPath then
      readDir dirPath
      |> attrNames
      |> filter (n: (readDir dirPath).${n} == "regular" && lib.hasSuffix ".nix" n)
      |> map (n: {
        stem = lib.removeSuffix ".nix" n;
        path = dirPath + "/${n}";
      })
    else
      [ ];

  # `[ { stem, path } ] -> (Path -> a) -> AttrSet`
  fromFiles = files: f: files |> map (e: lib.nameValuePair e.stem (f e.path)) |> lib.listToAttrs;

  # Merge a list of attrsets, dropping empty ones.
  mergeOpt = lib.foldl' (acc: x: acc // x) { };

  # Conditionally produce `{ ${key} = value; }` if `cond` is true.
  optEntry =
    key: cond: value:
    if cond then { ${key} = value; } else { };

  # "Manual": directory has default.nix

  mkManual = name: import (dir + "/${name}") args |> dbg "${name} (manual)";

  # "Auto-discovered": no default.nix

  mkAutoDiscovered =
    name:
    let
      base = dir + "/${name}";

      # Detection
      hasPackage = pathExists (base + "/package.nix");
      hasApp = pathExists (base + "/app.nix");
      hasCheck = pathExists (base + "/check.nix");
      hasNixosMod = pathExists (base + "/nixos-module.nix");
      hasHmMod = pathExists (base + "/home-manager-module.nix");

      pkgFiles = nixFilesIn (base + "/packages");
      appFiles = nixFilesIn (base + "/apps");
      checkFiles = nixFilesIn (base + "/checks");
      nixosFiles = nixFilesIn (base + "/nixos-modules");
      hmFiles = nixFilesIn (base + "/home-manager-modules");

      # All package names this module will produce.
      packageNames = lib.optional hasPackage name ++ map (f: f.stem) pkgFiles;

      hasAnyPackage = packageNames != [ ];

      hasAnyPerSystem = hasAnyPackage || hasApp || hasCheck || appFiles != [ ] || checkFiles != [ ];

      hasAnyFlake = hasNixosMod || hasHmMod || nixosFiles != [ ] || hmFiles != [ ];

      # Will produce `perSystem` outputs
      perSystemFn =
        { pkgs, config, ... }:
        let
          callPkg = path: pkgs.callPackage path { };
          importApp =
            path:
            import path {
              inherit pkgs;
              inherit (pkgs) lib;
            };
        in
        mergeOpt [
          (optEntry "packages" hasAnyPackage (
            lib.optionalAttrs hasPackage { ${name} = callPkg (base + "/package.nix"); }
            // fromFiles pkgFiles callPkg
          ))
          # Automatically add all discovered packages to the overlay.
          (optEntry "overlayAttrs" hasAnyPackage (
            lib.genAttrs packageNames (pname: config.packages.${pname})
          ))
          (optEntry "apps" (hasApp || appFiles != [ ]) (
            lib.optionalAttrs hasApp { ${name} = importApp (base + "/app.nix"); }
            // fromFiles appFiles importApp
          ))
          (optEntry "checks" (hasCheck || checkFiles != [ ]) (
            lib.optionalAttrs hasCheck { ${name} = callPkg (base + "/check.nix"); }
            // fromFiles checkFiles callPkg
          ))
        ];

      # Will produce `flake` outputs

      flakeAttrs = mergeOpt [
        (optEntry "nixosModules" (hasNixosMod || nixosFiles != [ ]) (
          lib.optionalAttrs hasNixosMod { ${name} = import (base + "/nixos-module.nix"); }
          // fromFiles nixosFiles import
        ))
        (optEntry "homeManagerModules" (hasHmMod || hmFiles != [ ]) (
          lib.optionalAttrs hasHmMod { ${name} = import (base + "/home-manager-module.nix"); }
          // fromFiles hmFiles import
        ))
      ];

      # Debug: list of discovered files.
      # Kinda duplicates the rest of the logic, but I only foresee a change <=>
      # there is a new category of outputs, like if I ever wanted `hydraJobs`
      # or `bundlers` here.
      discovered =
        lib.optional hasPackage "package.nix"
        ++ map (f: "packages/${f.stem}.nix") pkgFiles
        ++ lib.optional hasApp "app.nix"
        ++ map (f: "apps/${f.stem}.nix") appFiles
        ++ lib.optional hasCheck "check.nix"
        ++ map (f: "checks/${f.stem}.nix") checkFiles
        ++ lib.optional hasNixosMod "nixos-module.nix"
        ++ map (f: "nixos-modules/${f.stem}.nix") nixosFiles
        ++ lib.optional hasHmMod "home-manager-module.nix"
        ++ map (f: "home-manager-modules/${f.stem}.nix") hmFiles;

    in
    if hasAnyPerSystem || hasAnyFlake then
      lib.optionalAttrs hasAnyPerSystem { perSystem = perSystemFn; }
      // lib.optionalAttrs hasAnyFlake { flake = flakeAttrs; }
      |> dbg "${name} (auto): ${builtins.concatStringsSep ", " discovered}"
    else
      dbg "${name} (auto, empty)" null;

  # The "Do stuff"

  processSubdir =
    name: if pathExists (dir + "/${name}/default.nix") then mkManual name else mkAutoDiscovered name;
in
readDir dir
|> attrNames
|> filter (name: (readDir dir).${name} == "directory")
|> map processSubdir
|> filter (m: m != null)
