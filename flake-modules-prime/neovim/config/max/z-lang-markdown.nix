/**
  Markdown and general prose configuration.

  Features:

  - `Harper` :: helps find typos in Markdown and programming comments
  - `Markdownlint` (running as LSP through `EFM`) :: makes the Markdown more uniform
  - `marksman` :: detects broken links
  - `markdown-nvim` :: used for navigation and for working with Markdown lists
  - `mdsh` :: to execute embedded shell scripts
*/
{
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:
let
  markdownlintConfig =
    {
      default = true;
      # Disable 'first line should be a heading'
      MD041 = false;
      # Do not check for hard tabs in code blocks
      MD010.code_blocks = false;
      # Do not check for long lines in code blocks
      MD013.code_blocks = false;
      # Disable check for multiple top-level headings in the same document
      MD025 = false;
    }
    |> (pkgs.formats.toml { }).generate "mdlint.toml";
  # https://github.com/igorshubovych/markdownlint-cli
  markdownlintCli = "${lib.getExe pkgs.markdownlint-cli} --config ${markdownlintConfig}";

  efmMdConfig =
    {
      version = 2;
      root-markers = [ ".git/" ];
      # Credit:
      # https://github.com/helix-editor/helix/discussions/11639
      languages.markdown = [
        {
          # Looks like markdownlint-cli2 only operates on files
          lint-command = "${markdownlintCli} --stdin";
          lint-stdin = true;
          lint-after-open = true;
          lint-on-save = true;
          lint-formats = [
            "%f:%l %m"
            "%f:%l:%c %m"
            "%f: %l: %m"
          ];
        }
      ];
    }
    |> (pkgs.formats.yaml { }).generate "efm-config.yaml";
in
{
  plugins = [
    pkgs.vimPlugins.markdown-nvim
  ];

  config = [
    ''
      vim.lsp.config.marksman = {
        cmd = { "${lib.getExe pkgs.marksman}", "server" }
      }
      vim.lsp.enable('marksman')
    ''
    ''
      vim.lsp.config.harper_ls = {
        cmd = { "${lib.getExe pkgs-unstable.harper}", "--stdio" },
        settings = {
          ["harper-ls"] = {
            linters = {
              ToDoHyphen = false,
              ExpandMemoryShorthands = false
            }
          }
        }
      }
      vim.lsp.enable('harper_ls')

      -- Harper (esp. via Python docstrings, see
      -- https://github.com/Automattic/harper/issues/2417) can be too noisy
      -- to be useful in a given buffer. This toggles its diagnostics off/on
      -- for just the current buffer, leaving other buffers unaffected.
      local function toggle_harper_buffer()
        local bufnr = vim.api.nvim_get_current_buf()
        local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "harper_ls" })
        if #clients == 0 then
          vim.notify("Harper is not attached to this buffer", vim.log.levels.WARN)
          return
        end
        for _, client in ipairs(clients) do
          local ns = vim.lsp.diagnostic.get_namespace(client.id)
          local enabled = vim.diagnostic.is_enabled({ ns_id = ns, bufnr = bufnr })
          vim.diagnostic.enable(not enabled, { ns_id = ns, bufnr = bufnr })
        end
      end

      require("which-key").add({
        { "<leader>Th", toggle_harper_buffer, desc = "Toggle Harper spellcheck (this buffer)" },
      })
    ''
    ''
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "markdown" },
        command = "setlocal conceallevel=3 textwidth=80 nospell"
      })
    ''

    # markdown.nvim config
    ''
      require("markdown").setup({
        on_attach = function(bufnr)
          local map = vim.keymap.set
          local opts = { buffer = bufnr }
          map({ 'n', 'i' }, '<M-Return>', '<Cmd>MDListItemBelow<CR>', opts)
          map({ 'n', 'i' }, '<M-S-Return>', '<Cmd>MDListItemAbove<CR>', opts)
          map('n', '<localleader>x', '<Cmd>MDTaskToggle<CR>', opts)
          vim.api.nvim_buf_set_keymap(0, 'n', "<localleader><Return>", "<Cmd>!${lib.getExe pkgs.mdsh} --inputs %<CR>", {desc = "Run mdsh on this file" })
        end,
      })
    ''

    # efm-langserver for markdown
    ''
      -- Register a custom efm instance for markdown to avoid conflicts
      local configs = require 'lspconfig.configs'
      if not configs.efm_markdown then
        configs.efm_markdown = {
          default_config = {
            cmd = { "${lib.getExe pkgs.efm-langserver}", "-c", "${efmMdConfig}" },
            root_dir = require('lspconfig').util.root_pattern(".git", "."),
            filetypes = { "markdown" },
          }
        }
      end

      vim.lsp.config.efm_markdown = {
        cmd = { "${lib.getExe pkgs.efm-langserver}", "-c", "${efmMdConfig}" },
        settings = {},
        filetypes = { "markdown" },
        on_attach = function(buffer)
          vim.api.nvim_buf_set_keymap(0, 'n', "<localleader><S-F>", "<Cmd>!${markdownlintCli} --fix %<CR>", { desc = "Attempt to fix the file using markdownlint" })
        end,
      }
      vim.lsp.enable('efm_markdown')
    ''
  ];
}
