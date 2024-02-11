local telescope = require("telescope")
telescope.setup()

local wk = require("which-key")
wk.register({
	["<leader>"] = {
		function()
			require("telescope.builtin").find_files({ cwd = vim.env.PRJ_ROOT, path_display = { "truncate" } })
		end,
		"Find files in project",
	},
	l = {
		function()
			require("telescope.builtin").find_files({ cwd = vim.fn.expand("%:h") })
		end,
		"Look around in the current dir",
	},
	["b"] = { require("telescope.builtin").buffers, "Buffers" },
	["/"] = {
		function()
			require("telescope.builtin").live_grep({ glob_pattern = "!*.lock" })
		end,
		"Live grep",
	},
	["?"] = {
		function()
			require("telescope.builtin").live_grep({ glob_pattern = "!*.lock", cwd = vim.fn.expand("%:h") })
		end,
		"Live grep look around",
	},
	f = {
		r = { require("telescope.builtin").oldfiles, "Open recent files" },
	},
}, { prefix = "<leader>" })
