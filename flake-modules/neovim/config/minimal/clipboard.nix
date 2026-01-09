/**
  Configures clipboard share contents with the rest of the system.
*/
{ pkgs, lib, ... }:
{
  config = /* Lua */ ''
    vim.opt.clipboard = 'unnamed${lib.optionalString pkgs.stdenv.isLinux "plus"}'

    -- When vim is running remotely, use the OSC52 command to yank into clipboard
    -- This copies text back to the desktop session
    local is_ssh = os.getenv("SSH_CONNECTION") ~= nil

    if is_ssh then
      -- Implicit: requires vim.opt.clipboard = 'unnamedplus' to work
      vim.g.clipboard = {
        name = 'osc52',
        copy = {
            ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
            ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
        },
        paste = {
            ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
            ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
        },
      }
    end
  '';
}
