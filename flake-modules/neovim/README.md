This flake module provides:

- Packages:
    
    Packages are included so that I can run `nix run <flakeRef>#<pkgName>` in
    transient environments

    - `vim-minimal` -- minimal configuration with my settings. Useful for just a
      couple of plugins
    - `vim` -- slightly more advanced than `vim-minimal` but does not include
      LSPs
    - `vim-with-langs` -- adds LSPs to `vim`

    The packages are wrapped with extra binaries that are used by various
    plugins.

- Modules:

    - `homeManagerModules.vim` -- Home manager module that allows configuring
      the packages above
    - `nixosModules.vim` -- NixOS module that allows configuring the packages
      above

    Modules allow:
    - Extending the list of plugins
    - Appending raw lua to `init.lua`

# Plugins

## Minimal set

- `vim-surround` helps managing surrounding brackets/html tags/etc.
- `vim-commentary` file syntax-aware comments toggling
- `delimitMate` auto-close brackets in insert mode
- `vim-strip-trailing-whitespace` trims whitespace
- `vim-nftables` nftables language support. Needed outside language support for
  stripped down nvim on some machines
- `nvim-cmp` completions with:
    - `cmp-buffer` buffer completions
    - `cmp-cmdline` cmdline completions
    - `cmp-path` path completion
- `which-key`
- `hop`

## Standard set
- `nvim-web-devicons` icons, auto detected by telescope
- `cmp_luasnip` completions for snippets
- `todo-comments`
- `luasnip`
- `telescope`
- `telescope-file-browser`
- `vim-scratch-plugin`

## LSPs
- `cmp-nvim-lsp` LSP completions
- `fidget-nvim` UI for LSP
- Treesitter:
    - `nvim-treesitter`
    - `treesitter` grammars
- `nvim-lspconfig`
- `nvim-treesitter-context` adds LSP context on the top
- `nvim-ufo` for folds
- `nvim-colorizer-lua` for colorizing certain strings (colors in CSS)
- `gitsigns-nvim` shows state of line in the gutter and allows jumping
- `trouble-nvim` "pretty diagnostics, references, telescope results, quickfix
  and location list"
- Languages:
    - Nickel:
        - `vim-nickel`
        - LSP (nls)
    - Nix:
        - `vim-nix`
        - LSP (nixd + nil)
    - Bash: LSP (bash-language-server) + shellcheck
    - Markdown: LSP (marksman)
    - Rust: LSP (rust-analyzer)

# Architecture

Packages are extracted from the modules.
