/**
  Python configuration for Neovim.
*/
{
  pkgs,
  lib,
  self,
  pkgs-unstable,
  ...
}:
let
  pythonFormatter =
    self.inputs.my-flake-modules.packages.${pkgs.stdenv.hostPlatform.system}.my-python-formatter;
in
{
  config = # Lua
    ''
            -- -- Register a custom efm instance for python to avoid conflicts
            -- vim.lsp.config.ty = {
            --   cmd = { "${lib.getExe pkgs-unstable.ty}", "server" },
            -- }
            -- vim.lsp.enable('ty')
            -- 1. Register ty for Type Checking
      vim.lsp.config.ty = {
        cmd = { "${lib.getExe pkgs-unstable.ty}", "server" },
      --  root_dir = function(fname)
      --    return vim.fs.dirname(vim.fs.find({'.git', 'pyproject.toml'}, { upward = true })[1])
      --           or vim.loop.cwd()
      --  end,
      }
      vim.lsp.enable('ty')

      -- 2. "Merge" your custom logic without EFM
      -- We create an autocmd that attaches your custom tools to the buffer
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client.name == "ty" then
            -- Define your custom format function for <localleader>f
            vim.keymap.set('n', '<localleader>f', function()
              -- 1. Run your custom formatter (Nix-wrapped black/ruff)
              local cmd = "${lib.getExe pythonFormatter}"
              local file = vim.api.nvim_buf_get_name(0)

              -- Execute sync so the buffer updates immediately
              vim.fn.system(cmd .. " " .. vim.fn.shellescape(file))
              vim.cmd("edit!") -- Reload the file to see changes

              -- 2. Trigger ty to re-scan for new errors after format
              client.notify("textDocument/didChange", {
                 textDocument = { uri = vim.uri_from_bufnr(0), version = 0 },
                 contentChanges = {{ text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n") }}
              })
            end, { buffer = args.buf, desc = "Custom Python Format + Ty Refresh" })
          end
        end,
      })
    '';
}
