local trouble = require("trouble")

trouble.setup()

local wk = require("which-key")
wk.register({
	t = {
		A = { "<cmd>Trouble todo<cr>", "TODOs (Trouble)" },
		Q = { "<cmd>Trouble quickfix<cr>", "Quickfix (Trouble)" },
		L = { "<cmd>Trouble loclist<cr>", "Loclist (Trouble)" },
		T = { "<cmd>Trouble telescope<cr>", "Telescope (Trouble)" },
		D = { "<cmd>Trouble diagnostics<cr>", "Diagnostics (Trouble)" },
	},
}, { prefix = "<leader>" })

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
