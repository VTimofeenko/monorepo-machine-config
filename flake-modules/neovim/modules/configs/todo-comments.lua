-- The custom configuration maps the todo-comments to my usual levels of urgency
local tc = require("todo-comments")
local function shallowcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == "table" then
		copy = {}
		for orig_key, orig_value in pairs(orig) do
			copy[orig_key] = orig_value
		end
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

tc.setup()

local levelMap = {
	-- Three level urgency system
	["Info"] = { "Todo", "Note" },
	["Warn"] = { "Warn", "Perf", "Test" },
	["Err"] = { "Fix", "Hack" },
}

-- override the links
for key in pairs(levelMap) do
	local diagnosticHlGroup = "Diagnostic" .. key -- -> 'DiagnosticInfo', etc.

	for _, todoCommentsGroup in ipairs(levelMap[key]) do
		local groupText = vim.api.nvim_get_hl(0, { name = diagnosticHlGroup })
		groupText["italic"] = true -- to separate from normal comments
		local groupBadge = shallowcopy(groupText)
		groupBadge["reverse"] = true

		-- first the sign
		vim.api.nvim_set_hl(0, "TodoSign" .. todoCommentsGroup, { link = diagnosticHlGroup })
		vim.api.nvim_set_hl(0, "TodoFg" .. todoCommentsGroup, groupText)
		vim.api.nvim_set_hl(0, "TodoBg" .. todoCommentsGroup, groupBadge)
	end
end

-- clear treesitter's comment highlight
vim.api.nvim_set_hl(0, "Todo", {})

vim.keymap.set("n", "]t", function()
	tc.jump_next()
end, { desc = "Next todo comment" })

vim.keymap.set("n", "[t", function()
	tc.jump_prev()
end, { desc = "Previous todo comment" })

-- Convert the levelMap into a string, excluding NOTEs
local function mkNonNoteLevels()
	local result = ""
	for _, values in pairs(levelMap) do
		result = result .. table.concat(values, ",") .. ","
	end
	-- Remove the trailing comma and space
	result = result:sub(1, -3)
	result = string.gsub(result, "Note", "")

	return string.upper(result)
end
-- Extract only Error level todos
local function getErrorKeywords()
	local result = ""
	for key, values in pairs(levelMap) do
		if key == "Error" then
			result = result .. table.concat(values, ",") .. ","
		end
	end
	-- Remove the trailing comma and space
	result = result:sub(1, -3)

	return string.upper(result)
end

--

require("which-key").register({
	t = {
		name = "todos",
		a = { ":TodoTelescope<CR>", "All todos" },
		t = { ":TodoTelescope keywords=" .. mkNonNoteLevels() .. "<CR>", "Non-NOTE todos" },
		u = { ":TodoTelescope keywords=" .. getErrorKeywords() .. "<CR>", "Urgent todos" },
		n = { ":TodoTelescope keywords=NOTE<CR>", "NOTEs in project" },
	},
}, { prefix = "<leader>" })
