if vim.g.loaded_nix_lib_docs == 1 then
  return
end
vim.g.loaded_nix_lib_docs = 1

-- Provide backward compatibility aliases
package.preload["noogle"] = function()
  return require("nix-lib-docs")
end
package.preload["nix_lib_docs"] = function()
  return require("nix-lib-docs")
end

vim.api.nvim_create_user_command("NixLibDocs", function()
  require("nix-lib-docs").open()
end, { desc = "Fuzzy search Nix library function documentation (NixLibDocs)" })

-- Backward compatibility alias command
vim.api.nvim_create_user_command("NooglePicker", function()
  require("nix-lib-docs").open()
end, { desc = "Fuzzy search Nix library function documentation (alias to NixLibDocs)" })
