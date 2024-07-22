require("telescope").load_extension("file_browser")

local file_browser = require("telescope").extensions.file_browser.file_browser

require("which-key").add({
	{ "<leader>ff", file_browser, desc = "File browser in project root" },
	{
		"<leader>fl",
		function()
			file_browser({ cwd = vim.fn.expand("%:h") })
		end,
		desc = "File browser (look around)",
	},
})
