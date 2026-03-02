/**
  Helps to clearly show where my cursor is in yaml
*/
_: {
  config = ''
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "yaml" },
      command = "setlocal cursorcolumn cursorline",
    })
  '';
}
