vim.o.timeout = true
vim.o.timeoutlen = 300
vim.g.WK_shown = false

local wk = require("which-key")

wk.setup({
	key_labels = { ["<leader>"] = "SPC" },
})

-- Used to remap <leader>w -> +window dispatcher in Whichkey
-- Source https://github.com/folke/which-key.nvim/issues/428
local function wk_alias(keys)
	local timeout = vim.o.timeoutlen
	if vim.g.WK_shown then
		vim.o.timeoutlen = 0
	end
	local key_codes = vim.api.nvim_replace_termcodes(keys, true, false, true)
	vim.api.nvim_feedkeys(key_codes, "m", false)
	vim.defer_fn(function()
		vim.o.timeoutlen = timeout
		vim.g.WK_shown = false
	end, 10)
end

vim.api.nvim_create_autocmd({ "Filetype" }, {
	pattern = "WhichKey",
	callback = function()
		vim.g.WK_shown = true
	end,
})

wk.register({
	w = {
		function()
			wk_alias("<c-w>")
		end,
		"+window",
	},
}, { prefix = "<leader>" })
wk.register({
	["<C-w>d"] = { "<C-w>c", "Close window" },
})
-- Force bind the localleader, source
-- https://github.com/folke/which-key.nvim/issues/172
vim.api.nvim_set_keymap(
	"n",
	"<localleader>",
	"<cmd>lua require'which-key'.show(',', {mode='n'})<cr>",
	{ silent = true }
)

wk.register({
	T = {
		N = { "<cmd>set number! relativenumber!<cr>", "Toggle all numbers" },
		n = { "<cmd>set number!<cr>", "Toggle number" },
		r = { "<cmd>set relativenumber!<cr>", "Toggle relative numbers" },
		R = { "<cmd>set readonly!<cr>", "Toggle read-only flag" },
	},
}, { prefix = "<leader>" })
