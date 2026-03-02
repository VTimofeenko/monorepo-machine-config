/**
  Neovim function that implements a scrollback reader for kitty.

  Inspired by

  https://gist.github.com/galaxia4Eva/9e91c4f275554b4bd844b6feece16b3d?permalink_comment_id=5267474#gistcomment-5267474

  Much more advanced version:

  https://github.com/mikesmithgh/kitty-scrollback.nvim

  # Changes

  Rather than accepting input line from kitty, this pager just jumps to the
  last non-empty line.
*/
_: {
  config =
    # lua
    ''
      KITTY_SCROLLBACK = function()
          vim.opt.encoding='utf-8'
          -- Prevent auto-centering on click
          vim.opt.scrolloff = 0
          vim.opt.compatible = false
          vim.opt.number = false
          vim.opt.relativenumber = false
          vim.opt.termguicolors = true
          vim.opt.showmode = false
          vim.opt.ruler = false
          vim.opt.signcolumn=no
          vim.opt.showtabline=0
          vim.opt.laststatus = 0
          vim.o.cmdheight = 0
          vim.opt.showcmd = false
          vim.opt.scrollback = 100000
          vim.opt.clipboard:append('unnamedplus')
          local term_buf = vim.api.nvim_create_buf(true, false)
          local term_io = vim.api.nvim_open_term(term_buf, {})
          -- Map 'q' to first yank the visual selection (if any), which makes the copy selection work, and then quit.
          vim.api.nvim_buf_set_keymap(term_buf, 'v', 'q', 'y<Cmd>qa!<CR>', { })
          -- Regular quit mapping for normal mode
          vim.api.nvim_buf_set_keymap(term_buf, 'n', 'q', '<Cmd>qa!<CR>', { })
          local group = vim.api.nvim_create_augroup('kitty+page', {clear = true})

          local setCursor = function()
              local last_line = vim.fn.line("$")
              while last_line > 1 and vim.fn.getline(last_line):match("^%s*$") do
                last_line = last_line - 1
              end
              vim.api.nvim_win_set_cursor(0, { last_line, 0 })
          end

        vim.api.nvim_create_autocmd('ModeChanged', {
          group = group,
          buffer = term_buf,
          callback = function()
            local mode = vim.fn.mode()
            if mode == 't' then
              vim.cmd.stopinsert()
              vim.schedule(setCursor)
            end
          end,
        })

        vim.api.nvim_create_autocmd('VimEnter', {
          group = group,
          pattern = '*',
          once = true,
          callback = function(ev)
              local current_win = vim.fn.win_getid()
              -- Instead of sending lines individually, concatenate them.
              local main_lines = vim.api.nvim_buf_get_lines(ev.buf, 0, -2, false)
              local content = table.concat(main_lines, '\r\n')
              vim.api.nvim_chan_send(term_io, content .. '\r\n')

              -- Process the last line separately (without trailing \r\n)
              local last_line = vim.api.nvim_buf_get_lines(ev.buf, -2, -1, false)[1]
              if last_line then
                  vim.api.nvim_chan_send(term_io, last_line)
              end
              vim.api.nvim_win_set_buf(current_win, term_buf)
              vim.api.nvim_buf_delete(ev.buf, { force = true } )
              -- Use vim.defer_fn to make sure the terminal has time to process the content and the buffer is ready.
              vim.defer_fn(setCursor, 10)
          end
        })
      end
    '';
}
