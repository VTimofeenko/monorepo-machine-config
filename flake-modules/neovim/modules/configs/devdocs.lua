require("nvim-devdocs").setup({
	dir_path = vim.fn.stdpath("data") .. "/devdocs", -- installation directory
	telescope = {}, -- passed to the telescope picker
	float_win = { -- passed to nvim_open_win(), see :h api-floatwin
		relative = "editor",
		height = 25,
		width = 100,
		border = "rounded",
	},
	wrap = false, -- text wrap, only applies to floating window
	previewer_cmd = "glow", -- for example: "glow"
	cmd_args = { "-s", "dark" }, -- example using glow: { "-s", "dark", "-w", "80" }
	cmd_ignore = {}, -- ignore cmd rendering for the listed docs
	picker_cmd = true, -- use cmd previewer in picker preview
	picker_cmd_args = { "-s", "dark" }, -- example using glow: { "-s", "dark", "-w", "50" }
	mappings = { -- keymaps for the doc buffer
		open_in_browser = "",
	},
	ensure_installed = { "nix" }, -- get automatically installed
	-- after_open = function(bufnr) end, -- callback that runs after the Devdocs window is opened. Devdocs buffer ID will be passed in
})

require("which-key").register({
	K = { "<cmd>DevdocsOpen<cr>", "Open Devdocs" },
}, { prefix = "<localleader>" })
