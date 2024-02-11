-- Json and nix should be indented by 2 spaces
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "json", "nix" },
	command = "setlocal tabstop=2 shiftwidth=2",
})

-- Lua files should not expand tab
-- TODO: review this
vim.api.nvim_create_autocmd({
	"BufNewFile",
	"BufRead",
}, {
	pattern = "*.lua",
	command = "setlocal noexpandtab", -- stylua
})

-- Nix-specific file opener
local function open_file()
	local word_under_cursor = vim.fn.expand("<cWORD>") -- WORD under cursor

	local file_path = word_under_cursor

	if vim.bo.filetype == "nix" then
		-- Remove the trailing ';' if present
		-- TODO: maybe <cfile> would take care of removing extra symbols?
		word_under_cursor = word_under_cursor:gsub(";$", "")
		file_path = vim.fn.expand("%:p:h") .. "/" .. word_under_cursor
	end

	-- Check if it's a directory or a file
	local is_directory = vim.fn.isdirectory(file_path)

	if is_directory == 1 then
		-- It's a directory, open the corresponding default.nix file
		if vim.bo.filetype == "nix" then
			file_path = file_path .. "/default.nix"
		end
		-- Else -- just open netrw buffer there
	end

	if vim.fn.filereadable(file_path) == 0 then
		local choice = vim.fn.confirm("File " .. file_path .. " does not exist. Create?", "&Yes\n&Cancel", 1)
		if choice == 2 or choice == 0 then
			return -- Do not create the file if the prompt is canceled or "Cancel" is given
		end
	end

	vim.cmd("edit " .. file_path)
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "nix" },
	callback = function()
		local wk = require("which-key")
		wk.register({ ["gf"] = { open_file, "Open file under cursor" } })
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "markdown" },
	command = "setlocal conceallevel=3",
})
