# Minimal init.lua
_: {
  config =
    # lua
    ''
      -- Some general settings
      vim.keymap.set("n", " ", "<Nop>", { silent = true, remap = false })
      vim.g.mapleader = " "
      vim.g.maplocalleader = ","

      local options = vim.opt
      options.number = true
      options.relativenumber = true

      -- Search
      options.ignorecase = true
      options.smartcase = true
      options.incsearch = true
      options.expandtab = true
      options.tabstop = 4
      options.shiftwidth = 4
      options.autoread = true
      options.mouse = ""
      options.scrolloff = 4

      -- Highlight the yanked region
      local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
      vim.api.nvim_create_autocmd("TextYankPost", {
        callback = function()
          vim.highlight.on_yank({ timeout = 70 })
        end,
        group = highlight_group,
        pattern = "*",
      })

      -- Automatically resize splits when window size changes
      vim.api.nvim_create_autocmd("VimResized", {
        pattern = "*",
        callback = function()
          vim.api.nvim_command("redraw")
          vim.api.nvim_command("wincmd =")
        end,
      })

      -- Escape -> clear search highlight
      vim.api.nvim_set_keymap("n", "<ESC>", ":noh<CR>", { noremap = true, silent = true })

      -- Blackhole register prefix: <localleader>b + motion/operator behaves like "_,
      -- e.g. <localleader>bdG == "_dG, without needing to reach for shift-quote/shift-underscore
      vim.keymap.set({ "n", "x" }, "<localleader>b", '"_', { noremap = true })

      -- Display diagnostics as virtual lines, but only for the line the
      -- cursor is on. Sources like Harper can emit one diagnostic per word,
      -- and `virtual_lines = true` renders all of them, for every line in
      -- the buffer,  which balloons the buffer height into
      -- unreadable garbage. Scoping to the current line keeps the detailed
      -- view while editing without doing that.
      -- Also limit the spam to WARN+ severity.
      vim.diagnostic.config({
        virtual_lines = {
          current_line = true,
          severity = { min = vim.diagnostic.severity.WARN },
        }
      })
    '';
}
