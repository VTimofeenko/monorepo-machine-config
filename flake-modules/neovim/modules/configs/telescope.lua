local telescope = require("telescope")
telescope.setup()

local wk = require("which-key")
wk.add({
	{
		"<leader>/",
		function()
			require("telescope.builtin").live_grep({ glob_pattern = "!*.lock" })
		end,
		desc = "Live grep",
	},
	{
		"<leader><leader>",
		function()
			require("telescope.builtin").find_files({ cwd = vim.env.PRJ_ROOT, path_display = { "truncate" } })
		end,
		desc = "Find files in project",
	},
	{
		"<leader>?",
		function()
			require("telescope.builtin").live_grep({ glob_pattern = "!*.lock", cwd = vim.fn.expand("%:h") })
		end,
		desc = "Live grep look around",
	},
	{
		"<leader>fr",
		require("telescope.builtin").oldfiles,
		desc = "Open recent files",
	},
	{
		"<leader>l",
		function()
			require("telescope.builtin").find_files({ cwd = vim.fn.expand("%:h") })
		end,
		desc = "Look around in the current dir",
	},
})
