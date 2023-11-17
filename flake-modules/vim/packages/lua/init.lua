vim.g.mapleader = " "
vim.g.maplocalleader = ","

local options = vim.opt
-- These are on by default
-- syntax on
-- filetype plugin on
-- " cursor shapes in insert/normal modes
-- let &t_SI = "\e[6 q"
-- let &t_EI = "\e[2 q"
--
-- hi Visual term=bold,reverse cterm=bold,reverse
-- " make the completion visible on light background
-- hi Pmenu term=bold,reverse cterm=bold,reverse ctermfg=LightBlue ctermbg=Black
-- " set comments to be distinct from strings
-- hi Comment ctermfg=5

options.number = true
options.relativenumber = true
options.modelines = 1
options.ignorecase = true
options.smartcase = true
options.incsearch = true
options.expandtab = true
options.tabstop = 4
options.shiftwidth = 4
options.autoread = true
options.mouse = ""

-- Lua overwrites the groups, need to save them first
local pmenuGroup = vim.api.nvim_get_hl(0, { name = "Pmenu" })
pmenuGroup["cterm"] = {}
pmenuGroup["cterm"]["bold"] = true
-- pmenuGroup["cterm"]["reverse"] = true
pmenuGroup["ctermfg"] = "Magenta"
pmenuGroup["ctermbg"] = "Black"

local commentGroup = vim.api.nvim_get_hl(0, { name = "Comment" })
commentGroup["fg"] = "LightGray"
commentGroup["ctermfg"] = "LightGray"

vim.api.nvim_set_hl(0, "Pmenu", pmenuGroup)
vim.api.nvim_set_hl(0, "Comment", commentGroup)

-- I program a lot in languages that heavily use identifiers. Lots of green on the screen is distracting.
local identifier = vim.api.nvim_get_hl(0, { name = "Identifier" })
identifier["ctermfg"] = "LightBlue"
vim.api.nvim_set_hl(0, "Identifier", identifier)

-- Make Treesitter context a little more visible
vim.api.nvim_set_hl(0, "TreesitterContextBottom", { underline = true })

-- Escape -> clear search highlight
vim.api.nvim_set_keymap("n", "<ESC>", ":noh<CR>", { noremap = true, silent = true })

vim.api.nvim_create_autocmd({
	"BufNewFile",
	"BufRead",
}, {
	pattern = "*.nix",
	command = "setlocal tabstop=2 shiftwidth=2",
})

vim.api.nvim_create_autocmd({
	"BufNewFile",
	"BufRead",
}, {
	pattern = "*.lua",
	command = "setlocal noexpandtab", -- stylua
})

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
	command = "wincmd =",
	pattern = "*",
})
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
			print("kitty sent:", INPUT_LINE_NUMBER, CURSOR_LINE, CURSOR_COLUMN)
			vim.api.nvim_win_set_buf(current_win, term_buf)
			vim.api.nvim_buf_delete(ev.buf, { force = true })
		end,
	})
end

-- nvim part follows

-- set clipboard=unnamed${if pkgs.stdenv.system != "aarch64-darwin" then "plus" else ""}

-- " clear search highlights by hitting ESC
-- nnoremap <silent> <ESC> :noh<CR>
-- " set word end to dash for better "w"/"W" movement.
-- set iskeyword+=-
