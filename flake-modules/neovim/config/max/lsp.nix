{ pkgs, ... }:
{
  plugins = [
    pkgs.vimPlugins.nvim-lspconfig
    pkgs.vimPlugins.cmp-nvim-lsp
    pkgs.vimPlugins.nvim-docs-view
  ];

  config = [
    ''
      local wk = require("which-key")

      wk.add({
        { "<localleader>s", vim.lsp.buf.signature_help, desc = "See signature help" },
        { "<localleader>h", vim.lsp.buf.hover, desc = "Trigger hover" },
        { "<localleader>d", vim.diagnostic.open_float, desc = "Show diagnostics in a floating window." },
        { "<localleader>q", vim.diagnostic.setloclist, desc = "Add buffer diagnostics to the location list" },
        { "<localleader>r", vim.lsp.buf.rename, desc = "LSP rename" },
        { "<localleader>a", vim.lsp.buf.code_action, desc = "LSP code actions" },
        { "<localleader>f", vim.lsp.buf.format, desc = "LSP format" },
        { "<localleader>t", require("telescope.builtin").treesitter, desc = "Treesitter symbols" },
      })

      wk.add({
        { "gD", vim.lsp.buf.declaration, desc = "Go to declaration" },
        { "gd", vim.lsp.buf.definition, desc = "Go to definition" },
        { "gi", vim.lsp.buf.implementation, desc = "Go to implementation" },
        { "gr", vim.lsp.buf.references, desc = "Go to references" },
        { "[d", vim.diagnostic.goto_prev, desc = "Previous diagnostic" },
        { "]d", vim.diagnostic.goto_next, desc = "Next diagnostic" },
      })

      --vim.keymap.set('x', '\\a', function() vim.lsp.buf.code_action() end)

      local caps = vim.tbl_deep_extend(
        "force",
        vim.lsp.protocol.make_client_capabilities(),
        require("cmp_nvim_lsp").default_capabilities(),
        -- File watching is disabled by default for neovim.
        -- See: https://github.com/neovim/neovim/pull/22405
        { workspace = { didChangeWatchedFiles = { dynamicRegistration = true } } }
        )
    ''
    # Completion setup
    ''
      -- Prepend to the table to show lsp earlier
      table.insert(cmp_sources, 2, { name = "nvim_lsp" })
    ''
    # Shows a flyout with the docs
    # Auto-updated when moving the cursor
    ''
      vim.opt.updatetime = 300
      require("docs-view").setup({
          position = "right",
          update_mode = "auto",
      })
      wk.add({
        { "<localleader>TD", require("docs-view").toggle, desc = "Toggle doc pane" }
      })
    ''
  ];
}
