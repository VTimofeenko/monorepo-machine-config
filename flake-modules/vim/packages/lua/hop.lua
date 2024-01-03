local hop = require("hop")
hop.setup()
local wk = require("which-key")

wk.register({
	j = {
		function()
			hop.hint_words()
		end,
		"Jump",
	},
}, { prefix = "<leader>" })
wk.register({
	j = {
		function()
			hop.hint_words()
		end,
		"Jump",
	},
}, { prefix = "<leader>", mode = "v" })
