local wk = require("which-key")

wk.register({
	s = { vim.lsp.buf.signature_help, "See signature help" },
	h = { vim.lsp.buf.hover, "Trigger hover" },
	d = { vim.diagnostic.open_float, "Show diagnostics in a floating window." },
	q = { vim.diagnostic.setloclist, "Add buffer diagnostics to the location list" },
	r = { vim.lsp.buf.rename, "LSP rename" },
	a = { vim.lsp.buf.code_action, "LSP code actions" },
	f = { vim.lsp.buf.format, "LSP format" },
	t = { require("telescope.builtin").treesitter, "Treesitter symbols" },
}, { prefix = "<localleader>" })

wk.register({
	["gD"] = { vim.lsp.buf.declaration, "Go to declaration" },
	["gd"] = { vim.lsp.buf.definition, "Go to definition" },
	["gi"] = { vim.lsp.buf.implementation, "Go to implementation" },
	["gr"] = { vim.lsp.buf.references, "Go to references" },
	["[d"] = { vim.diagnostic.goto_prev, "Previous diagnostic" },
	["]d"] = { vim.diagnostic.goto_next, "Next diagnostic" },
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

require("lspconfig").ltex.setup({})
