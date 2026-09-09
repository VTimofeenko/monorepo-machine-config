/**
  `vidir` (from `moreutils`) thumbnail preview: the Lua part of the `vidir-img`
  feature.

  - Inert for any session missing `VIDIR_IMAGE_PREVIEW=1`.
  - Sets up a scratch buffer to the right of the `vidir` standard area.
  - All windows are closed by `:q`.
  - Renders thumbnails by the file number key.
  - Renders thumbnails when cursor moves into the line with an image, with a
    slight delay so if I mash `j` (I know) it does not block.
  - Preshrinks images for thumbnails.
  - Auto-cleanup when process exits

*/
{ pkgs, lib, ... }:
{
  config =
    # Lua
    ''
      local vidir_preview_group = vim.api.nvim_create_augroup("vidir_image_preview", { clear = true })

      vim.api.nvim_create_autocmd("VimEnter", {
        group = vidir_preview_group,
        once = true,
        callback = function()
          if vim.env.VIDIR_IMAGE_PREVIEW ~= "1" then
            return
          end

          local image = require("image")
          local list_win = vim.api.nvim_get_current_win()
          local list_buf = vim.api.nvim_get_current_buf()
          vim.b[list_buf].is_vidir = true

          -- Snapshot index -> original absolute path from the untouched
          -- buffer, before any renames are typed. This is deliberately not
          -- re-read later: it's the original files' identity, unaffected
          -- by in-progress (unsaved) edits to their names.
          local original_path_by_index = {}
          for _, l in ipairs(vim.api.nvim_buf_get_lines(list_buf, 0, -1, false)) do
            local idx, name = l:match("^(%d+)\t(.*)$")
            if idx then
              original_path_by_index[idx] = vim.fn.fnamemodify(name, ":p")
            end
          end

          -- Dedicated scratch window/buffer for the image -- never shares
          -- rows/columns with the filename list, so it can't overlap it.
          -- `rightbelow` pins it to the right of the listing regardless of
          -- the user's `splitright` setting.
          vim.cmd("rightbelow vsplit")
          local preview_win = vim.api.nvim_get_current_win()
          local preview_buf = vim.api.nvim_create_buf(false, true)
          vim.api.nvim_win_set_buf(preview_win, preview_buf)
          vim.bo[preview_buf].buftype = "nofile"
          vim.bo[preview_buf].swapfile = false
          vim.wo[preview_win].number = false
          vim.wo[preview_win].signcolumn = "no"
          vim.wo[preview_win].cursorline = false
          vim.api.nvim_set_current_win(list_win)

          -- The preview window has nothing of its own to quit out of, so
          -- `:wq`/`:q!` on the listing would otherwise leave it dangling.
          -- Deferred via `vim.schedule`: acting synchronously from inside
          -- `WinClosed`, while Neovim's own quit sequence for `list_win` is
          -- still unwinding, throws `E855: Autocommands caused command to
          -- abort`. And it has to be an actual `:quit`, not
          -- `nvim_win_close`: that API refuses to close the last window
          -- (like `:close`, not `:quit`), so it would silently no-op here.
          vim.api.nvim_create_autocmd("WinClosed", {
            group = vidir_preview_group,
            pattern = tostring(list_win),
            callback = function()
              vim.schedule(function()
                if vim.api.nvim_win_is_valid(preview_win) then
                  vim.api.nvim_set_current_win(preview_win)
                  pcall(vim.cmd, "silent! quit!")
                end
              end)
            end,
          })

          local current_image = nil
          local last_lnum = nil
          local shrink_cache = {}

          -- JPEGs get shrunk on load (see doc comment above); everything
          -- else is handed to image.nvim as-is.
          local function preview_path(path)
            if not path:lower():match("%.jpe?g$") then
              return path
            end
            if shrink_cache[path] then
              return shrink_cache[path]
            end
            local out = vim.fn.tempname() .. ".png"
            local result = vim
              .system({
                "${lib.getExe pkgs.imagemagick}",
                "-define",
                "jpeg:size=1600x1200",
                path,
                out,
              }, { timeout = 5000 })
              :wait()
            if result.code ~= 0 then
              shrink_cache[path] = path
              return path
            end
            shrink_cache[path] = out
            return out
          end

          local function preview_current_line()
            if not vim.api.nvim_win_is_valid(preview_win) then
              return
            end

            local lnum = vim.api.nvim_win_get_cursor(list_win)[1]
            local line = vim.api.nvim_buf_get_lines(list_buf, lnum - 1, lnum, false)[1] or ""
            local idx = line:match("^(%d+)\t")
            -- a bare name (no leading index) means it's one of the (rarer)
            -- invocations where explicit files were passed to vidir
            local path = idx and original_path_by_index[idx] or vim.fn.fnamemodify(line, ":p")

            if current_image then
              current_image:clear()
              current_image = nil
            end

            if not path or vim.fn.filereadable(path) == 0 then
              return
            end

            local ok, img = pcall(image.from_file, preview_path(path), {
              window = preview_win,
              buffer = preview_buf,
              x = 0,
              y = 0,
              width = vim.api.nvim_win_get_width(preview_win),
              height = vim.api.nvim_win_get_height(preview_win),
            })
            if ok and img then
              img:render()
              current_image = img
            end
          end

          -- Prevents costly rendering when the cursor travels through the line
          -- vertically
          local debounce_timer = nil
          vim.api.nvim_create_autocmd("CursorMoved", {
            group = vidir_preview_group,
            buffer = list_buf,
            callback = function()
              local lnum = vim.api.nvim_win_get_cursor(0)[1]
              if lnum == last_lnum then
                return
              end
              last_lnum = lnum
              if debounce_timer then
                debounce_timer:stop()
              else
                debounce_timer = vim.uv.new_timer()
              end
              debounce_timer:start(60, 0, vim.schedule_wrap(preview_current_line))
            end,
          })

          -- Correctly handles `dd -> render new image on the same line`
          vim.api.nvim_create_autocmd("TextChanged", {
            group = vidir_preview_group,
            buffer = list_buf,
            callback = function()
              last_lnum = vim.api.nvim_win_get_cursor(0)[1]
              preview_current_line()
            end,
          })

          vim.api.nvim_create_autocmd({ "BufLeave", "VimLeavePre" }, {
            group = vidir_preview_group,
            buffer = list_buf,
            callback = function()
              if current_image then
                current_image:clear()
                current_image = nil
              end
            end,
          })

          last_lnum = vim.api.nvim_win_get_cursor(list_win)[1]
          preview_current_line()
        end,
      })
    '';
}
