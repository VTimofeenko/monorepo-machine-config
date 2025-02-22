/**
  A telescope picker for docs from noogle

  https://noogle.dev/

  Uses output of `nix build .#data-json` from noogle and `easypick.nvim`. The
  output should be parsed into a JSON like so:

  ```
  jq -r 'map({(.meta.title): .content.content}) | add' ./noogle.json > parse.json

  ```
*/

{ pkgs, lib, ... }:

''
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local conf = require("telescope.config").values
local json = vim.fn.json_decode

local function noogle_picker()
  -- Read and parse JSON file
  local data = json(vim.fn.readfile("${./parse.json}"))
  if not data then
    print("Failed to parse JSON")
    return
  end

  -- Extract keys from JSON
  local keys = {}
  for k, _ in pairs(data) do
    table.insert(keys, k)
  end
  table.sort(keys)

  -- Create a Telescope picker
  pickers.new({}, {
    prompt_title = "Noogle Keys",
    finder = finders.new_table {
      results = keys,
    },
    sorter = conf.generic_sorter({}),
    previewer = previewers.new_termopen_previewer {
      get_command = function(entry)
        local key = entry.value
        local value = vim.inspect(data[key]) -- Pretty print JSON
        local raw_value = data[key]
        if raw_value == vim.NIL then
          raw_value = "No docs"
        end
        -- cleanup if needed?
        --raw_value = raw_value:gsub("%\n\n", "\r")
        --raw_value = raw_value:gsub("%\n", " ")

        -- Format as Markdown
        local markdown = "**Function:** `" .. key .. "`\n" .. raw_value .. ""

        -- Use printf to handle multi-line values correctly
        return { "sh", "-c", "printf %s " .. vim.fn.shellescape(markdown) .. " | grep -v ':::' | ${lib.getExe pkgs.glow} - -w 0 -n" }

      end,
    },
    attach_mappings = function(_, map)
      -- Insert the selected key into the current buffer
      map("i", "<CR>", function(prompt_bufnr)
        local selection = require("telescope.actions.state").get_selected_entry()
        print(selection.value)
        require("telescope.actions").close(prompt_bufnr)
        if selection then
          vim.api.nvim_put({ selection.value }, "c", true, true)
        end
      end)

      return true
    end,
  }):find()
end

-- Create a command to open the picker
vim.api.nvim_create_user_command("NooglePicker", function()
  noogle_picker()
end, {})

''
|> (it: { config = it;})
