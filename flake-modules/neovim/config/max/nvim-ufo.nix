{ pkgs, ... }:
{
  plugin = pkgs.vimPlugins.nvim-ufo;

  config = ''
    -- Taken from https://github.com/kevinhwang91/nvim-ufo

    vim.o.foldcolumn = "0" -- Disables the fold column marker (the one by the numbers)
    vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
    vim.o.foldlevelstart = 99
    vim.o.foldenable = true

    local wk = require("which-key")
    wk.add({
      { "zR", require("ufo").openAllFolds, desc = "Open all folds" },
      { "zM", require("ufo").closeAllFolds, desc = "Close all folds" },
    })
    require("ufo").setup({
      provider_selector = function(bufnr, filetype, buftype)
        return { "treesitter", "indent" }
      end,
    })
  '';
}
