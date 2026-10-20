# Minimal init.lua
_: {
  config =
    # lua
    ''
      -- Some general settings
      vim.keymap.set("n", " ", "<Nop>", { silent = true, remap = false })
      vim.g.mapleader = " "
      vim.g.maplocalleader = ","

      -- Enable project-level configuration files (.nvim.lua/.nvimrc/.exrc).
      -- Enabled <=> running as non-root
      -- Implementation notes:
      -- - `exrc` needs to be set very early
      -- - I am nulling out VIMINT to prevent it leaking into subshells/nested vims
      -- - see also `lib/mk-module.nix`as to how this is implemented.
      vim.o.exrc = vim.uv.getuid() ~= 0
      vim.env.VIMINIT = nil

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

      -- Scrollback viewers (kitty-scrollback.nix, zellij's scrollback.lua) set
      -- b:chomp_yank: their terminal buffers keep each row's trailing padding,
      -- strip it from yanks.
      vim.api.nvim_create_autocmd("TextYankPost", {
        group = vim.api.nvim_create_augroup("ChompYank", { clear = true }),
        callback = function(ev)
          local e = vim.v.event
          if not vim.b[ev.buf].chomp_yank or e.operator ~= "y" then
            return
          end
          local lines = vim.tbl_map(function(l)
            return (l:gsub("%s+$", ""))
          end, e.regcontents)
          if e.regname ~= "" then
            vim.fn.setreg(e.regname, lines, e.regtype)
            return
          end
          -- Unnamed yank: fix up "0 and, with clipboard=unnamed[plus], the
          -- clipboard. '"' last, otherwise it keeps the unchomped copy.
          vim.fn.setreg("0", lines, e.regtype)
          local cb = vim.o.clipboard
          local clip = cb:find("unnamedplus") and "+" or cb:find("unnamed") and "*"
          if clip then
            vim.fn.setreg(clip, lines, e.regtype)
          end
          vim.fn.setreg('"', lines, e.regtype)
        end,
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
