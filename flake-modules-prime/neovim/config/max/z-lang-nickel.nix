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

    # Force stop nickel_ls on buffer unload to avoid slow shutdown
    # Revisit later, this assert will take care of that
    (
      assert lib.assertMsg (lib.versionOlder settings.nlsPkg.version "1.16.0") "Check force exit nls hook in vim, may be fixed";
      ''
        vim.api.nvim_create_autocmd("BufUnload", {
          pattern = "*.ncl",
          callback = function()
          for _, client in ipairs(vim.lsp.get_clients({ name = "nickel_ls" })) do
          vim.lsp.stop_client(client.id, true)
          end
          end,
        })
      ''
    )

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
