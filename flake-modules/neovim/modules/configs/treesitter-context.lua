vim.api.nvim_set_hl(0, "TreesitterContextBottom", { underline = true })
local wk = require("which-key")

wk.register({
	u = { require("treesitter-context").go_to_context, "Jump to treesitter context" },
}, { prefix = "<localleader>" })

wk.register({
	T = { c = { require("treesitter-context").toggle, "Toggle treesitter context" } },
}, { prefix = "<leader>" })
