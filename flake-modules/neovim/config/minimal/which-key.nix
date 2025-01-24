{ pkgs, ... }:
{
  plugin = pkgs.vimPlugins.which-key-nvim;
  config =
    # lua
    ''
      vim.o.timeout = true
      vim.o.timeoutlen = 300

      local wk = require("which-key")

      wk.add({
        -- add "create file under cursor" binding
        { "gF", ":e <cfile><cr>", desc = "Open file under cursor even if it does not exist" },
        -- Quickfix quick jumps
        { "[q", "<cmd>cprevious<cr>", desc = "Quickfix previous" },
        { "]q", "<cmd>cnext<cr>", desc = "Quickfix next" },
      })

      wk.add({
        { "<leader>w", proxy = "<c-w>", group = "window"},
        { "<leader>wd", "<C-w>c", desc = "Close window" },
        -- Toggle shortcuts
        { "<leader>TN", "<cmd>set number! relativenumber!<cr>", desc = "Toggle all numbers" },
        { "<leader>TR", "<cmd>set readonly!<cr>", desc = "Toggle read-only flag" },
        { "<leader>Tn", "<cmd>set number!<cr>", desc = "Toggle number" },
        { "<leader>Tr", "<cmd>set relativenumber!<cr>", desc = "Toggle relative numbers" },
        -- Buffer shortcuts
        { "<leader>b", desc = "+buffer" },
        { "<leader>b[", "<cmd>bprevious<cr>", desc = "Previous buffer" },
        { "<leader>b]", "<cmd>bnext<cr>", desc = "Next buffer" },
        { "<leader>bd", "<cmd>bd<cr>", desc = "Close buffer" },
      })
    '';
}
