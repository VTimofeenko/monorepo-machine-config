local wk = require("which-key")

wk.register({
	T = {
		C = {
			function()
				vim.cmd.set("termguicolors!") -- Toggle termgui colors first
				require("colorizer").setup() -- Probably not ideal but OK
			end,
			"Toggle colorizer",
		},
	},
}, { prefix = "<leader>" })
