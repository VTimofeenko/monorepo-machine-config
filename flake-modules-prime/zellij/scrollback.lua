-- Colored scrollback for zellij's `EditScrollback ansi=true`: the dump is raw
-- ANSI, so instead of editing the file, replay it into a process-less terminal
-- buffer that renders the colors (same trick as kitty-scrollback.nvim).
local dump = vim.api.nvim_buf_get_name(0)
local f = assert(io.open(dump, "rb"))
-- Terminal wants CRLF, otherwise every line starts where the last one ended
local data = f:read("*a"):gsub("\n", "\r\n")
f:close()

local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_win_set_buf(0, buf)
vim.bo[buf].scrollback = 100000 -- nvim's max; zellij keeps 50000
local chan = vim.api.nvim_open_term(buf, {})
vim.api.nvim_chan_send(chan, data)
vim.cmd("silent! bwipeout " .. vim.fn.fnameescape(dump))

vim.keymap.set("n", "q", "<cmd>qa!<cr>", { buffer = buf })
-- Terminal output is processed asynchronously; once it's in, jump to the last
-- non-empty line (the dump includes the blank rest of the viewport)
vim.defer_fn(function()
  vim.cmd("normal! G")
  vim.fn.search([[\S]], "bcW")
end, 50)
