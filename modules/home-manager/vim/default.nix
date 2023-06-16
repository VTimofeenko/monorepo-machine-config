# [[file:../../../new_project.org::*Vim][Vim:1]]
# Home manager module that configures neovim with some plugins
{ pkgs, config, lib, ... }:
let
  cfg = config.programs.vt-vim-config;
in
{
  options.programs.vt-vim-config = with lib; {
    enableLangServers = mkOption {
      default = true;
      description = "Install language servers with vim. On by default.";
      type = types.bool;
    };
  };
  config = {
    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      extraPackages = lib.mkIf cfg.enableLangServers (builtins.attrValues {
        inherit (pkgs) rnix-lsp nil rust-analyzer;
        inherit (pkgs.nodePackages) bash-language-server;
      });
      plugins =
        (builtins.attrValues { inherit (pkgs.vimPlugins) vim-surround vim-commentary vim-nix delimitMate; })
        ++
        [
          {
            plugin = pkgs.vimPlugins.nvim-cmp;
            type = "lua";
            config =
              ''
                local cmp = require('cmp')
                cmp.setup {
                  snippet = {
                    expand = function(args)
                      require('luasnip').lsp_expand(args.body)
                    end,
                  },
                  mapping = {
                    ['<C-p>'] = cmp.mapping.select_prev_item(),
                    ['<C-n>'] = cmp.mapping.select_next_item(),
                    ['<C-space>'] = cmp.mapping.complete(),
                    ['<C-e>'] = cmp.mapping.close(),
                    ['<tab>'] = cmp.mapping.confirm { select = true },
                  },
                  sources = cmp.config.sources({
                    ${if cfg.enableLangServers
                      then
                        ''
                          { name = 'nvim_lsp' },
                          { name = 'luasnip' },
                        ''
                      else ""
                    }
                    { name = 'path' },
                    { name = 'buffer' },
                  }),
                }
                cmp.setup.cmdline('/', {
                    mapping = cmp.mapping.preset.cmdline(),
                    sources = {
                        { name = 'buffer' }
                    }
                })
                cmp.setup.cmdline(':', {
                    mapping = cmp.mapping.preset.cmdline(),
                    sources = cmp.config.sources({
                        { name = 'path' }
                    },
                    {
                      {
                        name = 'cmdline',
                        option = {
                            ignore_cmds = { 'Man', '!' }
                        }
                      }
                    })
                })
              '';
          }
          pkgs.vimPlugins.cmp-buffer
          pkgs.vimPlugins.cmp-cmdline
          pkgs.vimPlugins.cmp-path
          pkgs.vimPlugins.luasnip
          pkgs.vimPlugins.cmp_luasnip
        ]
        ++
        (
          if cfg.enableLangServers
          then
            [
              pkgs.vimPlugins.cmp-nvim-lsp
              {
                plugin = pkgs.vimPlugins.fidget-nvim;
                type = "lua";
                config = "require('fidget').setup {}";
              }
              {
                plugin = pkgs.vimPlugins.nvim-lspconfig;
                type = "lua";
                config =
                  ''
                    local lsp_mappings = {
                      { 'gD', vim.lsp.buf.declaration },
                      { 'gd', vim.lsp.buf.definition },
                      { 'gi', vim.lsp.buf.implementation },
                      { 'gr', vim.lsp.buf.references },
                      { '[d', vim.diagnostic.goto_prev },
                      { ']d', vim.diagnostic.goto_next },
                      { '<leader>' , vim.lsp.buf.hover },
                      { '<leader>s', vim.lsp.buf.signature_help },
                      { '<leader>d', vim.diagnostic.open_float },
                      { '<leader>q', vim.diagnostic.setloclist },
                      { '<leader>r', vim.lsp.buf.rename },
                      { '<leader>a', vim.lsp.buf.code_action },
                      { '<leader>f', vim.lsp.buf.format },
                              }
                    for i, map in pairs(lsp_mappings) do
                      vim.keymap.set('n', map[1], function() map[2]() end)
                    end
                    vim.keymap.set('x', '\\a', function() vim.lsp.buf.code_action() end)

                    local caps = vim.tbl_deep_extend(
                      'force',
                      vim.lsp.protocol.make_client_capabilities(),
                      require('cmp_nvim_lsp').default_capabilities(),
                      -- File watching is disabled by default for neovim.
                      -- See: https://github.com/neovim/neovim/pull/22405
                      { workspace = { didChangeWatchedFiles = { dynamicRegistration = true } } }
                                  );
                    require('lspconfig').bashls.setup {
                      autostart = true,
                      capabilities = caps,
                      filetypes = { 'zsh', 'bash', 'sh' },
                    }
                    require('lspconfig').nil_ls.setup {
                      autostart = true,
                      capabilities = caps,
                      cmd = { '${lib.getExe pkgs.nil}' },
                      settings = {
                        ['nil'] = {
                          testSetting = 42,
                          formatting = {
                            command = { "${lib.getExe pkgs.nixpkgs-fmt}" },
                          },
                        },
                      },
                    }
                    require('lspconfig').rust_analyzer.setup {
                      autostart = true,
                      capabilities = caps,
                      settings = {
                        ['rust-analyzer'] = {
                          imports = {
                            granularity = {
                              group = "module",
                            },
                            prefix = "self",
                          },
                          cargo = {
                            buildScripts = {
                              enable = true,
                            },
                          },
                          procMacro = {
                            enable = true
                          },
                          checkOnSave = {
                            command = "clippy",
                          },
                        }
                      }
                    }
                  '';
              }
            ]
          else [ ]
        );
      extraLuaConfig =
        ''
          -- Highlight the yanked region
          local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
          vim.api.nvim_create_autocmd('TextYankPost', {
            callback = function()
            vim.highlight.on_yank({timeout=70})
            end,
            group = highlight_group,
            pattern = '*',
          })
        '';
      extraConfig =
        ''
          syntax on

          let mapleader="\<Space>"

          nnoremap <leader>wl <C-w>l
          nnoremap <leader>wk <C-w>k
          nnoremap <leader>wj <C-w>j
          nnoremap <leader>wh <C-w>h

          nnoremap <silent> <leader>ws :split<CR>
          nnoremap <silent> <leader>wv :vsplit<CR>
          " close the _window_, not the buffer
          nnoremap <silent> <leader>wd <C-w>c

          set number relativenumber
          set modelines=1
          set autoindent
          set ignorecase
          set smartcase incsearch
          filetype plugin on

          " cursor shapes in insert/normal modes
          let &t_SI = "\e[6 q"
          let &t_EI = "\e[2 q"
          hi Visual term=bold,reverse cterm=bold,reverse
          " make the completion visible on light background
          hi Pmenu term=bold,reverse cterm=bold,reverse ctermfg=LightBlue ctermbg=Black
          set expandtab
          set tabstop=4
          set shiftwidth=4
          set autoread
          autocmd FileType nix setlocal tabstop=2 shiftwidth=2

          set clipboard=unnamed${if pkgs.stdenv.system != "aarch64-darwin" then "plus" else ""}
          set mouse=

          " clear search highlights by hitting ESC
          nnoremap <silent> <ESC> :noh<CR>
          " set word end to dash for better "w"/"W" movement.
          set iskeyword+=-
        '';
    };
  };
}
# Vim:1 ends here
