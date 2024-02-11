-- Taken from https://github.com/kevinhwang91/nvim-ufo

vim.o.foldcolumn = "0" -- Disables the fold column marker (the one by the numbers)
vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
vim.o.foldlevelstart = 99
vim.o.foldenable = true

local wk = require("which-key")
wk.register({
	["zR"] = { require("ufo").openAllFolds, "Open all folds" },
	["zM"] = { require("ufo").closeAllFolds, "Close all folds" },
})

-- Option 2: nvim lsp as LSP client
-- Tell the server the capability of foldingRange,
-- Neovim hasn't added foldingRange to default capabilities, users must add it manually
-- local capabilities = vim.lsp.protocol.make_client_capabilities()
-- capabilities.textDocument.foldingRange = {
-- 	dynamicRegistration = false,
-- 	lineFoldingOnly = true,
-- }
-- local language_servers = require("lspconfig").util.available_servers() -- or list servers manually like {'gopls', 'clangd'}
-- for _, ls in ipairs(language_servers) do
-- 	require("lspconfig")[ls].setup({
-- 		capabilities = capabilities,
-- 		-- you can add other fields for setting up lsp server in this table
-- 	})
-- end
-- require("ufo").setup()
--

-- Option 3: treesitter as a main provider instead
-- Only depend on `nvim-treesitter/queries/filetype/folds.scm`,
-- performance and stability are better than `foldmethod=nvim_treesitter#foldexpr()`
require("ufo").setup({
	provider_selector = function(bufnr, filetype, buftype)
		return { "treesitter", "indent" }
	end,
})
