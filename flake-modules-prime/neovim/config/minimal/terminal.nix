/**
  - Allows exiting from terminal mode to normal mode by hitting <Escape>.
*/
_: {
  config =
    # lua
    ''
      local wk = require("which-key")
      wk.add({
        {
          "<Esc>",
          "<C-\\><C-n>",
          desc = "Exit to normal mode from terminal mode",
          mode = "t",
        }
      })
    '';
}
