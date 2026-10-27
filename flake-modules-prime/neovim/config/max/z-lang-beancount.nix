/**
  A simple beancount server setup.

  beancount-language-server has no code actions, so a tiny in-process LSP
  ("beancount-actions") adds them to the regular code action menu:

  - Toggle the review flag (`*` <-> `!`) of the transaction under cursor
  - Insert `balance` assertions above the transaction, dated the day after
    it (i.e. balance at the end of the transaction's day, computed with
    bean-query from journal.beancount on disk). On a posting line it's only
    that account, on the header -- all Assets/Liabilities postings.
*/
{ pkgs, lib, ... }:
{
  config = [
    /* Lua */ ''
      vim.lsp.config.beancount = {
        cmd = { '${lib.getExe pkgs.beancount-language-server}', '--stdio'  },
        single_file_support = true,
        filetypes = { "beancount", "bean"},
        init_options = {
          journal_file = vim.fn.findfile("journal.beancount", ".;"),
        },
      }
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "beancount",
        callback = function()
          vim.opt_local.commentstring = "; %s"
        end,
      })
      vim.lsp.enable('beancount')
    ''
    /* Lua */ ''
      -- Custom code actions served by a tiny in-process LSP, so they show up in
      -- the regular vim.lsp.buf.code_action menu next to anything else.
      local BEAN_QUERY = '${lib.getExe' pkgs.beanquery "bean-query"}'
      local header_re = '^(%d%d%d%d%-%d%d%-%d%d)(%s+)(%S+)%s'

      local function is_header(l)
        local _, _, flag = l:match(header_re)
        return flag == '*' or flag == '!' or flag == 'txn'
      end

      -- Returns 0-based row of the transaction header the row belongs to, plus its line
      local function find_header(bufnr, row)
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, row + 1, false)
        for r = row, 0, -1 do
          local l = lines[r + 1]
          if is_header(l) then return r, l end
          -- Postings/metadata are indented; anything else ends the search
          if not l:match('^%s') or l:match('^%s*$') then return nil end
        end
      end

      -- Accounts of the transaction postings; only the one under the cursor if it is a posting
      local function txn_accounts(bufnr, header_row, row)
        local cur = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
        local acc = row ~= header_row and cur:match('^%s+[!*]?%s*([A-Z][%w%-]*:[%w%-:]+)')
        local res = { acc or nil }
        for r = header_row + 1, vim.api.nvim_buf_line_count(bufnr) - 1 do
          local l = vim.api.nvim_buf_get_lines(bufnr, r, r + 1, false)[1]
          if not l:match('^%s') or l:match('^%s*$') then break end
          local a = l:match('^%s+[!*]?%s*((%u%a*):[%w%-:]+)')
          local root = a and a:match('^(%u%a*):')
          if not acc and (root == 'Assets' or root == 'Liabilities') then table.insert(res, a) end
        end
        return res
      end

      local function journal_for(bufnr)
        local file = vim.api.nvim_buf_get_name(bufnr)
        local found = vim.fn.findfile('journal.beancount', vim.fs.dirname(file) .. ';')
        return found ~= "" and vim.fn.fnamemodify(found, ':p') or file
      end

      local function toggle_flag(bufnr, row)
        local header_row, line = find_header(bufnr, row)
        if not header_row then return vim.notify('Not in a transaction', vim.log.levels.WARN) end
        local date, ws, flag = line:match(header_re)
        local s = #date + #ws
        vim.api.nvim_buf_set_text(bufnr, header_row, s, header_row, s + #flag, { flag == '!' and '*' or '!' })
      end

      local function insert_balance(bufnr, row)
        local header_row, line = find_header(bufnr, row)
        if not header_row then return vim.notify('Not in a transaction', vim.log.levels.WARN) end
        if vim.bo[bufnr].modified then
          vim.notify('Buffer has unsaved changes; balance is computed from the file on disk', vim.log.levels.WARN)
        end
        local date = line:match(header_re)
        -- A balance directive asserts the balance at the *start* of its date,
        -- so the balance after this day is asserted on the next one
        local y, m, d = date:match('(%d+)-(%d+)-(%d+)')
        local next_day = os.date('%Y-%m-%d', os.time({ year = y, month = m, day = d + 1, hour = 12 }))
        local accounts = txn_accounts(bufnr, header_row, row)
        local out = {}
        for _, acc in ipairs(accounts) do
          local q = ("SELECT units(sum(position)) WHERE account = '%s' AND date <= %s"):format(acc, date)
          local res = vim.system({ BEAN_QUERY, '-q', '-f', 'csv', journal_for(bufnr), q }, { text = true }):wait()
          if res.code ~= 0 then
            return vim.notify('bean-query failed: ' .. (res.stderr or ""), vim.log.levels.ERROR)
          end
          local bal = vim.split(vim.trim(res.stdout), '\n')[2] or ""
          bal = vim.trim(bal:gsub('"', ""))
          if bal == "" then
            vim.notify(acc .. ': empty balance on ' .. date .. ', skipped', vim.log.levels.WARN)
          else
            for _, amount in ipairs(vim.split(bal, ',%s*')) do
              table.insert(out, ('%s balance %s  %s'):format(next_day, acc, amount))
            end
          end
        end
        if #out > 0 then
          table.insert(out, "")
          vim.api.nvim_buf_set_lines(bufnr, header_row, header_row, false, out)
        end
      end

      local commands = {
        ['beancount.toggle_flag'] = { title = 'Toggle review flag (* / !)', fn = toggle_flag },
        ['beancount.insert_balance'] = { title = 'Insert balance assertion above transaction', fn = insert_balance },
      }
      for name, c in pairs(commands) do
        vim.lsp.commands[name] = function(cmd, ctx)
          c.fn(vim.uri_to_bufnr(cmd.arguments[1]), cmd.arguments[2])
        end
      end

      local function server(dispatchers)
        local closing = false
        return {
          request = function(method, params, callback)
            if method == 'initialize' then
              callback(nil, { capabilities = { codeActionProvider = true } })
            elseif method == 'textDocument/codeAction' then
              local uri, row = params.textDocument.uri, params.range.start.line
              local actions = {}
              if find_header(vim.uri_to_bufnr(uri), row) then
                for name, c in pairs(commands) do
                  table.insert(actions, {
                    title = c.title,
                    command = { title = c.title, command = name, arguments = { uri, row } },
                  })
                end
                table.sort(actions, function(a, b) return a.title > b.title end)
              end
              callback(nil, actions)
            elseif method == 'shutdown' then
              callback(nil, nil)
            end
            return true, 1
          end,
          notify = function(method)
            if method == 'exit' then dispatchers.on_exit(0, 15) end
          end,
          is_closing = function() return closing end,
          terminate = function() closing = true end,
        }
      end

      vim.lsp.config['beancount-actions'] = { cmd = server, filetypes = { 'beancount' } }
      vim.lsp.enable('beancount-actions')
    ''
  ];
}
