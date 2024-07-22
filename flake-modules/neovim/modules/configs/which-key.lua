vim.o.timeout = true
vim.o.timeoutlen = 300
vim.g.WK_shown = false

local wk = require("which-key")

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

wk.add({
	-- Window shortcuts
	{
		"<leader>w",
		function()
			wk_alias("<c-w>")
		end,
		group = "window",
	},
	{ "<C-w>d", "<C-w>c", desc = "Close window" },
	-- Toggle shortcuts
	{ "<leader>TN", "<cmd>set number! relativenumber!<cr>", desc = "Toggle all numbers" },
	{ "<leader>TR", "<cmd>set readonly!<cr>", desc = "Toggle read-only flag" },
	{ "<leader>Tn", "<cmd>set number!<cr>", desc = "Toggle number" },
	{ "<leader>Tr", "<cmd>set relativenumber!<cr>", desc = "Toggle relative numbers" },
	-- Buffer shortcuts
	{ "<leader>b", desc = "+buffer" },
	{ "<leader>b[", "<cmd>bprevious<cr>", desc = "Previous buffer" },
	{ "<leader>b]", "<cmd>bnext<cr>", desc = "Next buffer" },
	{ "<leader>bb", require("telescope.builtin").buffers, desc = "Buffer selector" },
	{ "<leader>bd", "<cmd>bd<cr>", desc = "Close buffer" },
})
-- Force bind the localleader, source
-- https://github.com/folke/which-key.nvim/issues/172
vim.api.nvim_set_keymap(
	"n",
	"<localleader>",
	"<cmd>lua require'which-key'.show(',', {mode='n'})<cr>",
	{ silent = true }
)
