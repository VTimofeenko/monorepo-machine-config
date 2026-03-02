_: {
  config = ''
    vim.api.nvim_create_autocmd("FileType", {
    	pattern = { "json" },
    	command = "setlocal tabstop=2 shiftwidth=2",
    })
  '';
}
