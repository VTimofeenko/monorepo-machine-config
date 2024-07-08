vim.api.nvim_set_hl(0, "TreesitterContextBottom", { underline = true })
local wk = require("which-key")
local tsContext = require("treesitter-context")

tsContext.setup({
	max_lines = 4,
	on_attach = function()
		wk.register({
			u = { tsContext.go_to_context, "Jump to treesitter context" },
		}, { prefix = "<localleader>" })

		wk.register({
			T = { c = { tsContext.toggle, "Toggle treesitter context" } },
		}, { prefix = "<leader>" })
	end,
})
