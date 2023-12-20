require("telescope").load_extension("file_browser")

local file_browser = require("telescope").extensions.file_browser.file_browser

require("which-key").register({
	f = {
		f = { file_browser, "File browser in project root" },
		l = {
			function()
				file_browser({ cwd = vim.fn.expand("%:h") })
			end,
			"File browser (look around)",
		},
	},
}, { prefix = "<leader>" })
