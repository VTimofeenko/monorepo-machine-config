{
  pkgs,
  lib,
  colortheme,
}:
let
  inherit (colortheme.semantic)
    foundTextBg
    foundTextFg
    levelInfo
    levelWarn
    levelErr
    ;
  inherit (colortheme.raw) fg-alt slate;
in
lib.concatMapStringsSep "\n" builtins.readFile [
  ./configs/init/base.lua
  ./configs/init/file-specific.lua
  ./configs/init/kitty-scrollback-override.lua
]
+ ''
  vim.opt.clipboard = 'unnamed${if pkgs.stdenv.isLinux then "plus" else ""}'
''
# My theme
# TODO: add a nix-based generic function to override colors
+ ''
  -- Search highlights
  local searchResults = vim.api.nvim_get_hl(0, { name = "Search" })
  searchResults["fg"] = "${foundTextFg."#hex"}"
  searchResults["bg"] = "${foundTextBg."#hex"}"
  vim.api.nvim_set_hl(0, "Search", searchResults)

  -- Diagnostic signs
  local diagnosticInfo = vim.api.nvim_get_hl(0, { name = "DiagnosticInfo" })
  diagnosticInfo["fg"] = "${levelInfo."#hex"}"
  vim.api.nvim_set_hl(0, "DiagnosticInfo", diagnosticInfo)

  local diagnosticWarn = vim.api.nvim_get_hl(0, { name = "DiagnosticWarn" })
  diagnosticWarn["fg"] = "${levelWarn."#hex"}"
  vim.api.nvim_set_hl(0, "DiagnosticWarn", diagnosticWarn)

  local diagnosticErr = vim.api.nvim_get_hl(0, { name = "DiagnosticErr" })
  diagnosticErr["fg"] = "${levelErr."#hex"}"
  vim.api.nvim_set_hl(0, "DiagnosticErr", diagnosticErr)

  -- Manpages
  local manPageBold = vim.api.nvim_get_hl(0, { name = "manBold" })
  manPageBold["fg"] = "${fg-alt."#hex"}"
  vim.api.nvim_set_hl(0, "manBold", manPageBold)

  -- Statements
  local statement = vim.api.nvim_get_hl(0, { name = "Statement" })
  statement["fg"] = "${slate."#hex"}"
  vim.api.nvim_set_hl(0, "Statement", statement)

  -- General Title link
  local title = vim.api.nvim_get_hl(0, { name = "Title" })
  title["fg"] = "${fg-alt."#hex"}"
  vim.api.nvim_set_hl(0, "Title", title)

''
