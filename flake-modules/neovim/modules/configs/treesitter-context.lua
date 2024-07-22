vim.api.nvim_set_hl(0, "TreesitterContextBottom", { underline = true })
local wk = require("which-key")
local tsContext = require("treesitter-context")

tsContext.setup({
	max_lines = 4,
	on_attach = function()
		wk.add({
			{ "<localleader>u", tsContext.go_to_context, desc = "Jump to treesitter context" },
			{ "<leader>Tc", tsContext.toggle, desc = "Toggle treesitter context" },
		})
	end,
})
