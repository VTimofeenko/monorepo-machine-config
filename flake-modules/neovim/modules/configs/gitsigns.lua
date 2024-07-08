local gs = require("gitsigns")
local wk = require("which-key")

gs.setup({
	on_attach = function()
		wk.register({
			T = {
				B = {
					gs.toggle_current_line_blame,
					"Toggle current line blame",
				},
			},
			["]"] = {
				c = {
					function()
						gs.nav_hunk("next")
					end,
					"Next changed hunk",
				},
			},
			["["] = {
				c = {
					function()
						gs.nav_hunk("prev")
					end,
					"Previous changed hunk",
				},
			},
		})
	end,
})
