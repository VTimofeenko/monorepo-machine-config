/**
  A telescope picker for docs from noogle.

  https://noogle.dev/

  Uses a prebuilt `parse.json` (generated from noogle's `data-json` output):

  ```
    jq -r 'map({(.meta.title): .content.content}) | add' ./noogle.json > parse.json
  ```

  Registers a `:NooglePicker` command. No predefined keybind, invoke via command or <leader>:.
*/
{ pkgs, lib, ... }:
{
  config = /* Lua */ ''
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local previewers = require("telescope.previewers")
    local conf = require("telescope.config").values

    local function noogle_picker()
      local data = vim.fn.json_decode(vim.fn.readfile("${./parse.json}"))
      if not data then
        vim.notify("noogle: failed to parse JSON", vim.log.levels.ERROR)
        return
      end

      local keys = {}
      for k, _ in pairs(data) do
        table.insert(keys, k)
      end
      table.sort(keys)

      pickers.new({}, {
        prompt_title = "Noogle",
        finder = finders.new_table { results = keys },
        sorter = conf.generic_sorter({}),
        previewer = previewers.new_termopen_previewer {
          get_command = function(entry)
            local raw = data[entry.value]
            if raw == vim.NIL then raw = "No docs" end
            local markdown = "**Function:** `" .. entry.value .. "`\n" .. raw
            return { "sh", "-c", "printf %s " .. vim.fn.shellescape(markdown) .. " | grep -v ':::' | ${lib.getExe pkgs.glow} - -w 0 -n" }
          end,
        },
        attach_mappings = function(_, map)
          map("i", "<CR>", function(prompt_bufnr)
            local selection = require("telescope.actions.state").get_selected_entry()
            require("telescope.actions").close(prompt_bufnr)
            if selection then
              vim.api.nvim_put({ selection.value }, "c", true, true)
            end
          end)
          return true
        end,
      }):find()
    end

    vim.api.nvim_create_user_command("NooglePicker", noogle_picker, {})
  '';
}
