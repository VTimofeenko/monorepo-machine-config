local trouble = require("trouble")

trouble.setup()

local wk = require("which-key")
wk.add({
	{
		{ "<leader>tA", "<cmd>Trouble todo<cr>", desc = "TODOs (Trouble)" },
		{ "<leader>tD", "<cmd>Trouble diagnostics<cr>", desc = "Diagnostics (Trouble)" },
		{ "<leader>tL", "<cmd>Trouble loclist<cr>", desc = "Loclist (Trouble)" },
		{ "<leader>tQ", "<cmd>Trouble quickfix<cr>", desc = "Quickfix (Trouble)" },
		{ "<leader>tT", "<cmd>Trouble telescope<cr>", desc = "Telescope (Trouble)" },
	},
})

local open_with_trouble = require("trouble.sources.telescope").open

-- Use this to add more results without clearing the trouble list
local add_to_trouble = require("trouble.sources.telescope").add

local telescope = require("telescope")

telescope.setup({
	defaults = {
		mappings = {
			i = {
				["<m-t>"] = open_with_trouble,
				["<m-a>"] = add_to_trouble,
			},
			n = {
				["<m-t>"] = open_with_trouble,
				["<m-a>"] = add_to_trouble,
			},
		},
	},
})
