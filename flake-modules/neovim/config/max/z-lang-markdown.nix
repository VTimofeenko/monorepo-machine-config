/**
  Markdown and general prose configuration.

  Features:

  - `Harper` :: helps find typos in Markdown and programming comments
  - `Vale` :: helps with writing prose a bit better. It requires some out of band
    configuration by running `vale sync` with appropriate env config.
  - `Markdownlint` (running as LSP through `EFM`) :: makes the Markdown more uniform
  - `marksman` :: detects broken links
  - `markdown-nvim` :: used for navigation and for working with Markdown lists
  - `mdsh` :: to execute embedded shell scripts
*/
{
  pkgs,
  lib,
  ...
}:
let
  valeConfig =
    {
      sections = {
        "*" = {
          "BasedOnStyles" = "Vale, write-good, Readability";
          "write-good.E-Prime" = "NO"; # This is a bit arbitrary
          "Vale.Spelling" = "NO"; # Harper does this already
          # I am not smart enough to know what these mean. These checks are
          # very angry at me.
          "Readability.FleschReadingEase" = "NO";
          "Readability.FleschKincaid" = "NO";
          "Readability.SMOG" = "NO";
          "Readability.ColemanLiau" = "NO";
          "Readability.LIX" = "NO";
          "Readability.GunningFog" = "NO";
        };
      };
      globalSection = {
        "StylesPath" = "/home/spacecadet/.local/share/vale/styles";
        MinAlertLevel = "suggestion";
        Packages = "write-good, Readability";
      };
    }
    |> (pkgs.formats.iniWithGlobalSection { }).generate ".vale.ini";

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
        cmd = { "${lib.getExe pkgs.harper}", "--stdio" },
        settings = {
          ["harper-ls"] = {
            linters = {
              ToDoHyphen = false,
            }
          }
        }
      }
      vim.lsp.enable('harper_ls')
    ''
    ''
      -- see
      vim.env.VALE_CONFIG_PATH = "${valeConfig}"
      vim.env.VALE_STYLES_PATH = vim.env.XDG_DATA_HOME .. "/vale/styles"
      vim.lsp.config.vale_ls = {
        cmd = { "${lib.getExe pkgs.vale-ls}" },
        init_options = {
            installVale = false,
            configPath = "${valeConfig}",
            syncOnStartup = false,
        }
      }
      vim.lsp.enable('vale_ls')
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
      vim.lsp.config.efm = {
        cmd = { "${lib.getExe pkgs.efm-langserver}", "-c", "${efmMdConfig}" },
        settings = {},
        filetypes = { "markdown" },
        on_attach = function(buffer)
          vim.api.nvim_buf_set_keymap(0, 'n', "<localleader><S-F>", "<Cmd>!${markdownlintCli} --fix %<CR>", { desc = "Attempt to fix the file using markdownlint" })
        end,
      }
      vim.lsp.enable('efm')
    ''
  ];
}
