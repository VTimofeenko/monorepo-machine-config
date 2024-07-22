local wk = require("which-key")

wk.add({
	{ "<localleader>s", vim.lsp.buf.signature_help, desc = "See signature help" },
	{ "<localleader>h", vim.lsp.buf.hover, desc = "Trigger hover" },
	{ "<localleader>d", vim.diagnostic.open_float, desc = "Show diagnostics in a floating window." },
	{ "<localleader>q", vim.diagnostic.setloclist, desc = "Add buffer diagnostics to the location list" },
	{ "<localleader>r", vim.lsp.buf.rename, desc = "LSP rename" },
	{ "<localleader>a", vim.lsp.buf.code_action, desc = "LSP code actions" },
	{ "<localleader>f", vim.lsp.buf.format, desc = "LSP format" },
	{ "<localleader>t", require("telescope.builtin").treesitter, desc = "Treesitter symbols" },
})

wk.add({
	{ "gD", vim.lsp.buf.declaration, desc = "Go to declaration" },
	{ "gd", vim.lsp.buf.definition, desc = "Go to definition" },
	{ "gi", vim.lsp.buf.implementation, desc = "Go to implementation" },
	{ "gr", vim.lsp.buf.references, desc = "Go to references" },
	{ "[d", vim.diagnostic.goto_prev, desc = "Previous diagnostic" },
	{ "]d", vim.diagnostic.goto_next, desc = "Next diagnostic" },
})

--vim.keymap.set('x', '\\a', function() vim.lsp.buf.code_action() end)

local caps = vim.tbl_deep_extend(
	"force",
	vim.lsp.protocol.make_client_capabilities(),
	require("cmp_nvim_lsp").default_capabilities(),
	-- File watching is disabled by default for neovim.
	-- See: https://github.com/neovim/neovim/pull/22405
	{ workspace = { didChangeWatchedFiles = { dynamicRegistration = true } } }
)
require("lspconfig").bashls.setup({
	autostart = true,
	capabilities = caps,
	filetypes = { "zsh", "bash", "sh" },
})
require("lspconfig").nil_ls.setup({
	autostart = true,
	capabilities = caps,
	settings = {
		["nil"] = {
			formatting = {
				command = { "nixfmt" },
			},
		},
	},
})
require("lspconfig").rust_analyzer.setup({
	autostart = true,
	capabilities = caps,
	settings = {
		["rust-analyzer"] = {
			imports = {
				granularity = {
					group = "module",
				},
				prefix = "self",
			},
			cargo = {
				buildScripts = {
					enable = true,
				},
			},
			procMacro = {
				enable = true,
			},
			checkOnSave = {
				command = "clippy",
			},
		},
	},
})
require("lspconfig").nickel_ls.setup({
	autostart = true,
})

require("lspconfig").lua_ls.setup({
	on_init = function(client)
		local path = client.workspace_folders[1].name
		if not vim.loop.fs_stat(path .. "/.luarc.json") and not vim.loop.fs_stat(path .. "/.luarc.jsonc") then
			client.config.settings = vim.tbl_deep_extend("force", client.config.settings, {
				Lua = {
					runtime = {
						-- Tell the language server which version of Lua you're using
						-- (most likely LuaJIT in the case of Neovim)
						version = "LuaJIT",
					},
					formatting = {
						provider = "stylua",
						stylua = { path = "stylua" },
					},
					-- Make the server aware of Neovim runtime files
					workspace = {
						checkThirdParty = false,
						library = {
							vim.env.VIMRUNTIME,
							-- "${3rd}/luv/library"
							-- "${3rd}/busted/library",
						},
					},
				},
			})

			client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
		end
		return true
	end,
})

require("lspconfig").marksman.setup({})

-- Ltex setup with dictionary capabilities
--
-- Source: https://gist.githubusercontent.com/aghriss/90206887fef301febe6d644272bba367/raw/d260ff4417010918764ee8219df4482fbb308a90/ltex.lua
local S = {}

-- define the files for each language
-- new words will be added to the last file in the language table
S.dictionaries = {
	-- The path is slightly changed
	["en-US"] = { vim.fn.stdpath("data") .. "/site/spell/en.utf-8.add" },
}

-- function to avoid interacting with the table directly
function S.getDictFiles(lang)
	local files = S.dictionaries[lang]
	if files then
		return files
	else
		return nil
	end
end

-- combine words from all the files. Each line should contain one word
function S.readDictFiles(lang)
	local files = S.getDictFiles(lang)
	local dict = {}
	if files then
		for _, file in ipairs(files) do
			local f = io.open(file, "r")
			if f then
				for l in f:lines() do
					table.insert(dict, l)
				end
			else
				print("Can not read dict file %q", file)
			end
		end
	else
		print("Lang %q has no files", lang)
	end
	return dict
end

-- Append words to the last element of the language files
function S.addWordsToFiles(lang, words)
	local files = S.getDictFiles(lang)
	if not files then
		return print("no dictionary file defined for lang %q", lang)
	else
		local file = io.open(files[#files - 0], "a+")
		if file then
			for _, word in ipairs(words) do
				file:write(word .. "\n")
			end
			file:close()
		else
			return print("Failed insert %q", vim.inspect(words))
		end
	end
end

-- The following part is a classic lspconfig config section
local lspconfig = require("lspconfig")
-- notifying wkspc will refresh the settings that contain the dictionary
local wkspc = "workspace/didChangeConfiguration"
-- instead of looping through the list of clients and check client.name == 'ltex' (which many solutions out there are doing)
-- We attach the command function to the bufer then ltex is loaded
local function on_attach(client, bufnr)
	-- require("lspconfig").on_attach(client, bufnr)
	-- the second argumeng is named 'ctx', but we don't need it here
	--- command = {argument={...}, command=..., title=...}
	local addToDict = function(command, _)
		for _, arg in ipairs(command.arguments) do
			-- not the most efficent way, we could readDictFiles once per lang
			for lang, words in pairs(arg.words) do
				S.addWordsToFiles(lang, words)
				client.config.settings.ltex.dictionary = {
					[lang] = S.readDictFiles(lang),
				}
			end
		end
		-- notify the client of the new settings
		return client.notify(wkspc, client.config.settings)
	end
	-- add the function to handle the command
	-- then lsp.commands does not find the handler, it will look at opts.handler["workspace/executeCommand"]
	vim.lsp.commands["_ltex.addToDictionary"] = addToDict
end
-- 'pluging.config.lspconfig' is from NvChad configuraion
lspconfig.ltex.setup({
	on_attach = on_attach,
	-- start by hand only. Live checking is sluggish
	-- start command
	-- :lua require"lspconfig".ltex.setup{}
	autostart = false,
	-- capabilities = require("lspconfig").capabilities,
	capabilities = caps,
	filetypes = { "tex", "markdown" },
	settings = {
		ltex = {
			dictionary = {
				["en-US"] = S.readDictFiles("en-US"),
			},
		},
	},
})
