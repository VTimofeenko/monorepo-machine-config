/**
  Sets up LSP and plugins for nickel.
*/
{
  pkgs,
  lib,
  pkgs-unstable,
  ...
}:
let
  settings.nlsPkg = pkgs-unstable.nls;
in
{
  plugins = [
    /**
      `vim-nickel` provides syntax highlighting, file detection and indentation for Nickel source files.
      It's needed to actually kick off the LSP
    */
    pkgs.vimPlugins.vim-nickel
  ];

  config = [
    # LSP configuration
    ''
      vim.lsp.config.nickel_ls = {
        cmd = { '${lib.getExe settings.nlsPkg}' },
        autostart = true,
      }
      vim.lsp.enable('nickel_ls')
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
