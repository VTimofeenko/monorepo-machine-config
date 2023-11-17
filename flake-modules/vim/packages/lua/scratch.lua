-- Config for vim scratch plugin

-- Open scratch from bottom side
vim.g["scratch_top"] = 0
-- Disable default mappings
vim.g["scratch_no_mappings"] = 1
-- Disable autohide
vim.g["scratch_autohide"] = 0

local wk = require("which-key")
wk.register({
	x = { ":Scratch<CR>", "Open scratch" },
}, { prefix = "<leader>" })
