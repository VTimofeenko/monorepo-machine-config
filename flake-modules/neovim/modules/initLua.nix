{
  pkgs,
  lib,
  colortheme,
}:
let
  # TODO: have this depend on the withLangs value

  # Flakeref is used so that nixd does not evaluate the changing flake over and over
  # Upside: much faster startup
  #
  # Downside: relies on the config being pushed, so
  # it's possible that some new thing is not yet available if the inputs were
  # bumped but repo was not pushed
  flakeRef = "github:VTimofeenko/monorepo-machine-config";

  /**
    Simple trace check for versions of the package.

    A bit naive in that it relies on semver and ignores funky(0.0.1 vs 0.0.1-pre-alpha-10) versions.

    Helps keeping overrides to a minimum by alerting me if an override may be obsolete.
  */
  traceIfNewerThan =
    package: targetVersion: x:
    let
      mkVerAttrset =
        y:
        [
          "major"
          "minor"
          "patch"
        ]
        |> map (it: {
          name = it;
          value = lib.versions."${it}";
        })
        |> builtins.listToAttrs
        |> lib.mapAttrs (
          n: v:
          let
            version = y.version or y;
          in
          v version
        );
      pkgVersion = mkVerAttrset package;
      cmpVersion = mkVerAttrset targetVersion;
    in
    lib.traceIf (
      (pkgVersion.major > cmpVersion.major)
      || (pkgVersion.minor > cmpVersion.minor)
      || (pkgVersion.patch != cmpVersion.patch)
    ) "${package.name} override is for older version. Probably worth revisiting" x;

  # nixdLive is an override for nixd that should fix 100% CPU when pipe is used.
  nixdLive = traceIfNewerThan pkgs.nixd "2.5.1" (
    pkgs.nixd.overrideAttrs (old: {
      version = "2.5.1-override";
      src = pkgs.fetchFromGitHub {
        owner = "nix-community";
        repo = "nixd";
        rev = "17b7dfd1b4a888ded1bbf875b7601e40f43f94e8";
        hash = "sha256-5+ul4PxMgPkmGLB8CYpJcIcRDY/pJgByvjIHDA1Gs5A=";
      };
    })
  );

  # nilLive is an override for nil that should support pipes
  nilLive = traceIfNewerThan pkgs.nil "2024-08-06" (
    pkgs.nil.overrideAttrs (old: rec {
      src = pkgs.fetchFromGitHub {
        owner = "oxalica";
        repo = "nil";
        rev = "2e24c9834e3bb5aa2a3701d3713b43a6fb106362";
        hash = "sha256-DCIVdlb81Fct2uwzbtnawLBC/U03U2hqx8trqTJB7WA=";
      };

      # overriding cargoHash does not work; this is the way to do it
      cargoDeps = old.cargoDeps.overrideAttrs {
        name = "nil-vendor.tar.gz";
        inherit src;
        outputHash = "sha256-FppdLgciTzF6tBZ+07IEzk5wGinsp1XUE7T18DCGvKg=";
      };
    })
  );

  inherit (colortheme.semantic."#hex")
    foundTextBg
    foundTextFg
    levelInfo
    levelWarn
    levelErr
    ;
  inherit (colortheme.raw."#hex") fg-alt slate;
in
lib.concatMapStringsSep "\n" builtins.readFile [
  ./configs/init/base.lua
  ./configs/init/file-specific.lua
  ./configs/init/kitty-scrollback-override.lua
]
+ ''
  vim.opt.clipboard = 'unnamed${if pkgs.stdenv.isLinux then "plus" else ""}'
''
# Nix LSPs
# I am using _both_ nixd and nil. Nixd helps with custom options whereas nil works for builtins and code actions.
+ ''
  require("lspconfig").nil_ls.setup({
    cmd = { "${lib.getExe nilLive}" },
    autostart = true,
    capabilities = caps,
    settings = {
      ["nil"] = {
        formatting = {
          command = { "nixfmt" },
        },
        flake = {
          autoEvalInputs = true,
          autoArchive = true,
        },
      },
    },
  })
''
+ ''
  require("lspconfig").nixd.setup({
    cmd = { "${lib.getExe nixdLive}" },
    autostart = true,
    capabilities = caps,
    settings = {
      ["nixd"] = {
        nixpkgs = {
          expr = "import (builtins.getFlake \"${flakeRef}\").inputs.nixpkgs { }",
        },
        options = {
          home_manager = {
            expr = "(builtins.getFlake \"${flakeRef}\").outputs.legacyPackages.${pkgs.stdenv.system}.deck.options"
          },
        },
      },
    },
  })
''
# My theme
# TODO: add a nix-based generic function to override colors
+ ''
  -- Search highlights
  local searchResults = vim.api.nvim_get_hl(0, { name = "Search" })
  searchResults["fg"] = "${foundTextFg}"
  searchResults["bg"] = "${foundTextBg}"
  vim.api.nvim_set_hl(0, "Search", searchResults)

  -- Diagnostic signs
  local diagnosticInfo = vim.api.nvim_get_hl(0, { name = "DiagnosticInfo" })
  diagnosticInfo["fg"] = "${levelInfo}"
  vim.api.nvim_set_hl(0, "DiagnosticInfo", diagnosticInfo)

  local diagnosticWarn = vim.api.nvim_get_hl(0, { name = "DiagnosticWarn" })
  diagnosticWarn["fg"] = "${levelWarn}"
  vim.api.nvim_set_hl(0, "DiagnosticWarn", diagnosticWarn)

  local diagnosticErr = vim.api.nvim_get_hl(0, { name = "DiagnosticErr" })
  diagnosticErr["fg"] = "${levelErr}"
  vim.api.nvim_set_hl(0, "DiagnosticErr", diagnosticErr)

  -- Manpages
  local manPageBold = vim.api.nvim_get_hl(0, { name = "manBold" })
  manPageBold["fg"] = "${fg-alt}"
  vim.api.nvim_set_hl(0, "manBold", manPageBold)

  -- Statements
  local statement = vim.api.nvim_get_hl(0, { name = "Statement" })
  statement["fg"] = "${slate}"
  vim.api.nvim_set_hl(0, "Statement", statement)

  -- General Title link
  local title = vim.api.nvim_get_hl(0, { name = "Title" })
  title["fg"] = "${fg-alt}"
  vim.api.nvim_set_hl(0, "Title", title)

  -- Type
  local typeHl = vim.api.nvim_get_hl(0, { name = "Type" })
  typeHl["fg"] = "LightGreen"
  typeHl["underline"] = true
  vim.api.nvim_set_hl(0, "Type", typeHl)

''
