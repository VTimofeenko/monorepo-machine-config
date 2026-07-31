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

    local ufo_loaded = false
    local function ensure_ufo()
      local ufo = require("ufo")
      if not ufo_loaded then
        ufo.setup({
          provider_selector = function(bufnr, filetype, _buftype)
            return { "treesitter", "indent" }
          end,
        })
        ufo_loaded = true
      end
      return ufo
    end

    wk.add({
      { "zR", function() ensure_ufo().openAllFolds() end, desc = "Open all folds" },
      { "zM", function() ensure_ufo().closeAllFolds() end, desc = "Close all folds" },
    })
  '';
}
