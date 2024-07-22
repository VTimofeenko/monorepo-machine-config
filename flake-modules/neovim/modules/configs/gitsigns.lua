local gs = require("gitsigns")
local wk = require("which-key")

gs.setup({
	on_attach = function()
		wk.add({
			{
				"TB",
				gs.toggle_current_line_blame,
				desc = "Toggle current line blame",
			},
			{
				"]c",
				function()
					gs.nav_hunk("next")
				end,
				desc = "Next changed hunk",
			},
			{
				"[c",
				function()
					gs.nav_hunk("prev")
				end,
				desc = "Previous changed hunk",
			},
		})
	end,
})
