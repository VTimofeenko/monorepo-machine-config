-- Some general settings
vim.g.mapleader = " "
vim.g.maplocalleader = ","

local options = vim.opt
options.number = true
options.relativenumber = true

options.modelines = 1

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

local wk = require("which-key")
wk.add({
	-- add "create file under cursor" binding
	{ "gF", ":e <cfile><cr>", desc = "Open file under cursor even if it does not exist" },
	-- Quickfix quick jumps
	{ "[q", "<cmd>cprevious<cr>", desc = "Quickfix previous" },
	{ "]q", "<cmd>cnext<cr>", desc = "Quickfix next" },
})

-- Escape -> clear search highlight
vim.api.nvim_set_keymap("n", "<ESC>", ":noh<CR>", { noremap = true, silent = true })
