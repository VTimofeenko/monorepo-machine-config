/**
  Configures a way to show the git state of a file in vim gutter

  Main use cases:
  - Quick navigation to a changed block
  - Showing the state of a line (staged/unstaged/etc.)
  - Staging/unstaging lines and hunks
*/
{ pkgs, ... }:
{
  plugin = pkgs.vimPlugins.gitsigns-nvim;
  config = /* lua */ ''
    local gs = require("gitsigns")
    local wk = require("which-key")

    -- Code below sets up a tiny wrapper function around stage_hunk to flash the staged/unstaged regions
    -- It has not been tested too thoroughly but it seems to work fine for my use case.
    -- It uses internals of gitsigns so use at your own risk.
    local cache = require('gitsigns.cache')

    -- Flash a specific range of lines (1-based inclusive)
    local function flash_range(bufnr, start_line, end_line)
      local ns = vim.api.nvim_create_namespace('gitsigns_flash')
      vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

      local buf_line_count = vim.api.nvim_buf_line_count(bufnr)
      for i = start_line, end_line do
        if i <= buf_line_count then
          vim.api.nvim_buf_add_highlight(bufnr, ns, 'IncSearch', i - 1, 0, -1)
        end
      end

      vim.defer_fn(function()
        if vim.api.nvim_buf_is_valid(bufnr) then
          vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
        end
      end, 70)
    end

    -- Calculate range for a Hunk object and flash it
    local function flash_hunk(hunk, bufnr)
      local start_line = hunk.added.start
      local count = hunk.added.count
      local end_line = start_line + (count > 0 and count - 1 or 0)

      if start_line == 0 then
        start_line = 1
        end_line = 1
      elseif count == 0 then
        end_line = start_line
      end

      flash_range(bufnr, start_line, end_line)
    end

    local my_gitsigns_actions = {}

    function my_gitsigns_actions.stage_hunk()
      local bufnr = vim.api.nvim_get_current_buf()
      local mode = vim.api.nvim_get_mode().mode

      if mode:match('^[vV\22]') then
        -- VISUAL MODE: Stage selection
        local line_v = vim.fn.line('v')
        local line_cur = vim.fn.line('.')
        local start_line = math.min(line_v, line_cur)
        local end_line = math.max(line_v, line_cur)

        -- Exit Visual Mode to allow clean flashing and staging
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)

        -- Flash the selection
        flash_range(bufnr, start_line, end_line)

        -- Call gitsigns with the range
        gs.stage_hunk({start_line, end_line})
      else
        -- NORMAL MODE: Stage hunk at cursor
        local bcache = cache.cache[bufnr]
        if bcache then
          -- Use greedy=false to avoid async overhead/errors and get cached hunk
          local hunk = bcache:get_hunk(nil, false, false)
          if not hunk then
            hunk = bcache:get_hunk(nil, false, true) -- Check staged
          end

          if hunk then
            flash_hunk(hunk, bufnr)
          end
        end
        gs.stage_hunk()
      end
    end

    gs.setup({
      on_attach = function()
        wk.add({
          {
            "TB",
            gs.toggle_current_line_blame,
            desc = "Toggle current line blame",
          },
          {
            "]c",
            function()
              gs.next_hunk({target = "all"})
            end,
            desc = "Next changed hunk",
          },
          {
            "[c",
            function()
              gs.prev_hunk({target = "all"})
            end,
            desc = "Previous changed hunk",
          },
          {
            "[c",
            function()
              gs.prev_hunk({target = "all"})
            end,
            desc = "Previous changed hunk",
          },
          {
            "<Space>gs",
            my_gitsigns_actions.stage_hunk,
            desc = "Stage hunk",
            mode = { "n", "v" },
          }
        })
      end,
    })
  '';
}
