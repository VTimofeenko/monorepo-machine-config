This flake module provides:

- Packages:
    
    - `vim-minimal` -- minimal configuration with my settings. Useful for just a
      couple of plugins
    - `vim` -- slightly more advanced than `vim-minimal` but does not include
      LSPs
    - `vim-with-langs` -- adds LSPs to `vim`

    The point of having separate packages is the ability to run them in
    transient environments.

    To run a package: `nix run <flakeRef>#vim`

- Modules:

    - `homeManagerModules.vim` -- Home manager module that allows configuring
      the packages above
    - `nixosModules.vim` -- NixOS module that allows configuring the packages
      above

    Modules allow:
    - Extending the list of plugins
    - Appending raw Lua to `init.lua`

# Features

## Minimal set

<!--TODO: just parse with perl. Take first comment-->

- [Auto-closing brackets](./config/minimal/auto-close-brackets.nix)
- [Single system clipboard](./config/minimal/clipboard.nix)
- [Toggleable comments](./config/minimal/commentary.nix)
- [Completions](./config/minimal/completions.nix):
    - File
    - Path
- [hop](./config/minimal/hop.nix) to make quick jumps
- [General config](./config/minimal/init-lua.nix) that's not too interesting
- [Special config](./config/minimal/kitty-scrollback.nix) for kitty scrollback
  pager
- [Surround plugin](./config/minimal/vim-surround.nix)
- [Which-key] for showing the key binds

## Standard set

- [Telescope](./config/standard/telescope.nix) for finding files
- [Todo-comments](./config/standard/todo-comments.nix) for highlighting TODO/FIXME/WARN
- [Scratch plugin](./config/standard/vim-scratch-plugin.nix) for quick one off scratch buffers
- [JSON support](./config/standard/z-lang-json.nix)
    - Formatting
    - Schemas
- [YAML support](./config/standard/z-lang-yaml.nix)

## LSPs

- [Treesitter](./config/max/treesitter.nix)
- [General lspconfig stuff](./config/max/lsp.nix)
- [Gitsigns](./config/max/gitsigns.nix) to highlight git status of lines and
  quick navigation to changed lines
- [Fidget](./config/max/fidget-nvim.nix) as a UI for LSP
- [Luasnip](./config/max/luasnip.nix) for snippets
- Colorizer
- [UFO](./config/max/nvim-ufo.nix) for LSP-aware folds
- [Trouble](./config/max/trouble-nvim.nix) for diagnostic search
- Languages (with language servers):
    - [Bash](./config/max/z-lang-bash.nix)
    - [Markdown](./config/max/z-lang-markdown.nix)
    - [Nickel](./config/max/z-lang-nickel.nix)
    - [Nix](./config/max/z-lang-nix.nix) with `nixd` and `nil`
    - [Rust](./config/max/z-lang-rust.nix)
    - [TOML](./config/max/z-lang-toml.nix)

# Architecture

The key implementation is in [the `mk-module` function](./lib/mk-module.nix).

Flake module generates packages by evaluating the module and extracting the
package attribute from the configuration.
