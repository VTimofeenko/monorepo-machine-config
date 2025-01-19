/**
  Sets up LSP and plugins for nickel.
*/
{
  pkgs,
  lib,
  pkgs-unstable,
  ...
}:
{
  plugins = [
    /**
      vim-nickel provides syntax highlighting, file detection and identation for Nickel source files.
      It's needed to actually kick off the LSP
    */
    pkgs.vimPlugins.vim-nickel
  ];

  config = [
    # LSP configuration
    ''
      require("lspconfig").nickel_ls.setup({
        cmd = { '${lib.getExe pkgs-unstable.nls}' },
        autostart = true,
      })

    ''
    # nickel templates for luasnip
    ''
      ls.add_snippets("nickel", {
        -- "Let .. in" template
        s("let", {
          -- Instead of a linebreak, tab by hand
          t({ "let", "\t" }),
          i(1),
          t({ "", "in" }),
        }),
      }, {
        key = "nickel",
      })
    ''
  ];
}
