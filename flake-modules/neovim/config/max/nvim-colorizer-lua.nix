{ pkgs, ... }:
{
  plugin = pkgs.vimPlugins.nvim-colorizer-lua;
  config = ''
    local wk = require("which-key")

    wk.add({
      {
        "<leader>TC",
        function()
          vim.cmd.set("termguicolors!") -- Toggle termgui colors first
          require("colorizer").setup() -- Probably not ideal but OK
        end,
        desc = "Toggle colorizer",
      },
    })
  '';
}
