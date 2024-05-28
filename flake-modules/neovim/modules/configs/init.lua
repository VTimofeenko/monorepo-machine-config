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
options.scrolloff = 4 -- Keep 4 lines of context around the cursor. Also helps with treesitter context

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

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "json", "nix" },
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
	pattern = "*",
	callback = function()
		vim.api.nvim_command("redraw")
		vim.api.nvim_command("wincmd =")
	end,
})

-- Function to handle default imports in nix
local function open_file()
	local word_under_cursor = vim.fn.expand("<cWORD>") -- WORD under cursor

	local file_path = word_under_cursor

	if vim.bo.filetype == "nix" then
		-- Remove the trailing ';' if present
		word_under_cursor = word_under_cursor:gsub(";$", "")
		file_path = vim.fn.expand("%:p:h") .. "/" .. word_under_cursor
	end

	-- Check if it's a directory or a file
	local is_directory = vim.fn.isdirectory(file_path)

	if is_directory == 1 then
		-- It's a directory, open the corresponding default.nix file
		if vim.bo.filetype == "nix" then
			file_path = file_path .. "/default.nix"
		end
		-- Else -- just open netrw buffer there
	end

	if vim.fn.filereadable(file_path) == 0 then
		local choice = vim.fn.confirm("File " .. file_path .. " does not exist. Create?", "&Yes\n&Cancel", 1)
		if choice == 2 or choice == 0 then
			return -- Do not create the file if the prompt is canceled or "Cancel" is given
		end
	end

	vim.cmd("edit " .. file_path)
end

local wk = require("which-key")
wk.register({ ["gf"] = { open_file, "Open file under cursor" } })
wk.register({ ["[q"] = { "<cmd>cprevious<cr>", "Quickfix previous" } })
wk.register({ ["]q"] = { "<cmd>cnext<cr>", "Quickfix next" } })
-- wk.register({ ["Tq"] = { "<cmd><cr>", "Quickfix toggle" } }) -- TODO: Implement toggle quickfix

-- TODO: Add shortcuts for deadnix-quickfix and statix-quickfix

-- nvim part follows

-- set clipboard=unnamed${if pkgs.stdenv.system != "aarch64-darwin" then "plus" else ""}

-- " clear search highlights by hitting ESC
-- nnoremap <silent> <ESC> :noh<CR>
-- " set word end to dash for better "w"/"W" movement.
-- set iskeyword+=-
