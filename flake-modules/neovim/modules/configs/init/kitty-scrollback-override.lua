-- Apply these settings if invoked as a pager for the last command in kitty
KITTY_SCROLLBACK = function(INPUT_LINE_NUMBER, CURSOR_LINE, CURSOR_COLUMN)
	vim.opt.encoding = "utf-8"
	vim.opt.compatible = false
	-- Looks like this is needed to not wrap end lines?
	vim.opt.number = false
	vim.opt.relativenumber = false
	vim.opt.termguicolors = true
	vim.opt.showmode = false
	vim.opt.ruler = false
	vim.opt.laststatus = 0
	vim.opt.showcmd = false
	vim.opt.scrollback = 1000
	local term_buf = vim.api.nvim_create_buf(true, false)
	local term_io = vim.api.nvim_open_term(term_buf, {})
	vim.api.nvim_buf_set_keymap(term_buf, "n", "q", "<Cmd>q<CR>", {})
	local group = vim.api.nvim_create_augroup("kitty+page", {})

	vim.api.nvim_create_autocmd("ModeChanged", {
		group = group,
		buffer = term_buf,
		command = "stopinsert",
	})

	vim.api.nvim_create_autocmd("VimEnter", {
		group = group,
		pattern = "*",
		once = true,
		callback = function(ev)
			local current_win = vim.fn.win_getid()
			for _, line in ipairs(vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false)) do
				vim.api.nvim_chan_send(term_io, line)
				vim.api.nvim_chan_send(term_io, "\r\n")
			end
			-- Debug
			--print("kitty sent:", INPUT_LINE_NUMBER, CURSOR_LINE, CURSOR_COLUMN)
			vim.api.nvim_win_set_buf(current_win, term_buf)
			vim.api.nvim_buf_delete(ev.buf, { force = true })
			-- Jump to the end of file
			-- Usually ctrl+shift+g does CURSOR_COLUMN=0, CURSOR_LINE=0
			if CURSOR_LINE == 0 then
				-- Jump to the very end
				-- This also serves as a fallback behavior
				vim.api.nvim_command("normal! G")
				-- Try to jump back to the first chevron
				-- FIXME: does not work :(
				--
				-- local line_num = vim.fn.search('❯ ', 'b')
				-- print(line_num)
				-- if line_num > 0 then
				-- 	vim.api.nvim_win_set_cursor(0, { line_num, 0 })
				-- end
			else
				vim.api.nvim_win_set_cursor(0, { CURSOR_LINE + 1, CURSOR_COLUMN })
			end
		end,
	})
end
