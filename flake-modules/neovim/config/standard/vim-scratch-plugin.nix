{ pkgs, ... }:
{
  plugin = pkgs.vimUtils.buildVimPlugin {
    name = "vim-scratch";
    src = pkgs.fetchFromGitHub {
      owner = "mtth";
      repo = "scratch.vim";
      rev = "adf826b1ac067cdb4168cb6066431cff3a2d37a3";
      hash = "sha256-P8SuMZKckMu+9AUI89X8+ymJvJhlsbT7UR7XjnWwwz8=";
    };
  };
  config =
    # lua
    ''
      -- Open scratch from bottom side
      vim.g["scratch_top"] = 0
      -- Disable default mappings
      vim.g["scratch_no_mappings"] = 1
      -- Disable autohide
      vim.g["scratch_autohide"] = 0

      local wk = require("which-key")
      wk.add({
        { "<leader>x", ":Scratch<CR>", desc = "Open scratch" },
      })
    '';
}
