local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local M = {}

local exitmsg_ns = vim.api.nvim_create_namespace("nvim.terminal.exitmsg")

local function make_previewer(docs)
  return previewers.new_termopen_previewer({
    get_command = function(entry)
      local raw = docs[entry.value]
      if raw == vim.NIL or raw == nil then
        raw = "No documentation available."
      end

      local markdown = "**Function:** `" .. entry.value .. "`\n\n" .. raw

      -- Strip nixpkgs docbook callout artifacts (::: ...)
      markdown = markdown:gsub(":::[^\n]*\n?", "")

      -- Promote nixdoc headings (### Inputs -> # Inputs, #### -> ##)
      -- so glow renders H1 section badges with inverted background/foreground:
      markdown = markdown:gsub("\n### ", "\n# ")
      markdown = markdown:gsub("\n#### ", "\n## ")
      markdown = markdown:gsub("^### ", "# ")
      markdown = markdown:gsub("^#### ", "## ")

      return {
        "sh",
        "-c",
        "printf %s " .. vim.fn.shellescape(markdown) .. " | glow - -w 0 -n",
      }
    end,
  })
end

function M.open(opts)
  local nix_lib_docs = require("nix-lib-docs")
  local docs = nix_lib_docs.get_docs()

  local keys = {}
  for k, _ in pairs(docs) do
    table.insert(keys, k)
  end
  table.sort(keys)

  -- Autocmd to remove "[Process exited 0]" virtual text on TermClose
  local augroup = vim.api.nvim_create_augroup("NixLibDocsPreviewExitMsg", { clear = true })
  vim.api.nvim_create_autocmd("TermClose", {
    group = augroup,
    callback = function(ev)
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(ev.buf) then
          vim.api.nvim_buf_clear_namespace(ev.buf, exitmsg_ns, 0, -1)
        end
      end)
    end,
  })

  pickers.new(opts or {}, {
    prompt_title = "Nix Lib Documentation",
    finder = finders.new_table({ results = keys }),
    sorter = conf.generic_sorter(opts or {}),
    previewer = make_previewer(docs),
    attach_mappings = function(prompt_bufnr, map)
      map("i", "<CR>", function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selection then
          vim.api.nvim_put({ selection.value }, "c", true, true)
        end
      end)
      return true
    end,
  }):find()
end

return M
