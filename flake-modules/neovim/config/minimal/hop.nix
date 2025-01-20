{ pkgs, ... }:
{
  plugin = pkgs.vimPlugins.hop-nvim;
  config =
    # lua
    ''
      local hop = require("hop")
      hop.setup()
      local wk = require("which-key")

      wk.add({
        {
          "<leader>j",
          function()
            hop.hint_words()
          end,
          desc = "Jump",
        },
        {
          "<leader>j",
          function()
            hop.hint_words()
          end,
          desc = "Jump",
          mode = "v",
        },
      })
    '';

}
