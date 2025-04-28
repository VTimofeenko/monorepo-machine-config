/**
  Sets up LSP and plugins for nix development.

  Features:
  - Two LSPs:
    - nixd :: nixd uses standard parser. I am using it mostly for lib functions and options completions
    - nil :: I am using nil for code action and completions

      Full set of features:
      https://github.com/oxalica/nil/blob/main/docs/features.md#cli-features

    Both are using live versions so that pipe syntax is supported

  - Treesitter support for nested strings (hmts-nvim) allows highlighting, say, bash strings inside nix strings
  - Formatting using nix-rfc-style-format
  - Snippets:
    - (let .. in)
    - (if then else)
    - Common module arguments ({ pkgs, lib, config, ... }:})
    - `writeShellApplication` with args

  TODO: add hover data for common functions (maybe source from devdocs or noogle?)
*/
{
  pkgs,
  lib,
  self,
  ...
}:
let
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

in
{
  plugins = [
    pkgs.vimPlugins.hmts-nvim
    # vim-nix provides nice indentation
    pkgs.vimPlugins.vim-nix
  ];

  config = [
    # LSP Configs
    ''
      require("lspconfig").nil_ls.setup({
        cmd = { "${lib.getExe nilLive}" },
        autostart = true,
        capabilities = caps,
        settings = {
          ["nil"] = {
            formatting = {
              command = { "${lib.getExe pkgs.nixfmt-rfc-style}" },
            },
            flake = {
              autoEvalInputs = true,
              autoArchive = true,
            },
          },
        },
      })

      require("lspconfig").nixd.setup({
        cmd = { "${lib.getExe pkgs.nixd}" },
        autostart = true,
        capabilities = caps,
        settings = {
          ["nixd"] = {
            nixpkgs = {
              expr = "import (builtins.getFlake \"${flakeRef}\").inputs.nixpkgs { }",
            },
            options = {
              home_manager = {
                ${
                  # This parameter needs a nix path to an attribute set
                  # containing homeConfigurations.
                  # I am reusing this flake's output. This is not ideal as it
                  # works as an implicit dependency, but should work for now.
                  #
                  # FIXME: create a fake homeConfigurations output in the vim flake module for this
                  assert builtins.hasAttr "deck" self.outputs.legacyPackages.${pkgs.stdenv.system}.homeConfigurations;
                  # \" around flakeRef is load bearing
                  ''expr = "(builtins.getFlake \"${flakeRef}\").outputs.legacyPackages.${pkgs.stdenv.system}.homeConfigurations.deck.options"''
                }
              },
            },
          },
        },
      })
    ''
    ''
      ls.add_snippets("nix", {
        -- "Let .. in" template
        s("let", {
          -- Instead of a linebreak, tab by hand
          t({ "let", "\t" }),
          i(1),
          t({ "", "in" }),
        }),
        -- if .. then .. else template
        s("if", {
          t({ "if " }),
          i(1),
          t({ " then " }),
          i(2),
          t({ " else " }),
          i(3),
        }),
        -- /* */ comment
        s("/*", {
          t({ "/* " }),
          i(1),
          t({ " */" }),
        }),
        -- /** */ Docstring
        s("/**", {
          t({ "/** " }),
          i(1),
          t({ " */" }),
        }),
        s("inherit", {
          t({ "inherit (" }),
          i(1),
          t({ ")" }),
          i(2),
          t({ ";" }),
        }),
        s("writeShellApplication", {
          t({ "writeShellApplication {", "\tname = " }),
          i(1),
          t({ ";", "", "\truntimeInputs = [" }),
          i(2),
          t({ "];", "", "\ttext =" }),
          i(3),
          t({ "}" }),
        }),
        s("assertMsg", {
          t({ "assert lib.assertMsg " }),
          i(1),
          t({ "pred \"" }),
          i(2),
          t({ "\";" }),
          i(3),
        }),
        s("{ pkgs, lib, config, ... }:", {
          t({ "{ pkgs, lib, config, ... }:" }),
        }),
      }, {
        key = "nix",
      })
    ''
    # This is a small file opener utility. If 'gF' is pressed while on a
    # directory, vim will assume that I meant to open `default.nix` in that
    # directory
    ''
      -- Nix-specific file opener
      local function open_file()
        local word_under_cursor = vim.fn.expand("<cWORD>") -- WORD under cursor

        local file_path = word_under_cursor

        if vim.bo.filetype == "nix" then
          -- Remove the trailing ';' if present
          -- TODO: maybe <cfile> would take care of removing extra symbols?
          word_under_cursor = word_under_cursor:gsub(";$", "")
          file_path = vim.fn.expand("%:p:h") .. "/" .. word_under_cursor
        end

        -- Check if it's a directory or a file
        local is_directory = vim.fn.isdirectory(file_path)

        if is_directory == 1 then
          -- It's a directory, open the corresponding default.nix file
          if vim.bo.filetype == "nix" then
            file_path = file_path .. "/default.nix"
          end
          -- Else -- just open netrw buffer there
        end

        if vim.fn.filereadable(file_path) == 0 then
          local choice = vim.fn.confirm("File " .. file_path .. " does not exist. Create?", "&Yes\n&Cancel", 1)
          if choice == 2 or choice == 0 then
            return -- Do not create the file if the prompt is canceled or "Cancel" is given
          end
        end

        vim.cmd("edit " .. file_path)
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "nix" },
        callback = function()
          local wk = require("which-key")
          wk.add({
            { "gf", open_file, desc = "Open file under cursor" },
          })
        end,
      })

    ''
  ];
}
