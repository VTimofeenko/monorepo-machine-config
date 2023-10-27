# [[file:../../new_project.org::*Vim][Vim:1]]
# Home manager module that configures neovim with some plugins
{ localFlake, inputs }:
{ pkgs, config, lib, ... }:
let
  cfg = config.programs.vt-vim-config;
  hmts = pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "hmts";
    version = "master";
    src = localFlake.inputs.hmts;
  };
  scratch-plugin = pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "scratch";
    version = "master";
    src = localFlake.inputs.vim-scratch-plugin;
  };
  pkgs-unstable = localFlake.inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.system};
  stable-plugins = pkgs.vimPlugins;
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
        inherit (pkgs) shellcheck;
        inherit (pkgs) lua-language-server;
      });
      plugins =
        (builtins.attrValues {
          inherit (pkgs.vimPlugins) vim-surround vim-commentary vim-nix delimitMate vim-strip-trailing-whitespace;
          inherit (pkgs-unstable.vimPlugins) vim-nickel;
        })
        ++
        [
          {
            plugin = stable-plugins.todo-comments-nvim; # Highlights TODO/NOTE/etc comments
            type = "lua";
            config = # lua
              ''
                -- The custom configuration maps the todo-comments to my usual levels of urgency
                local tc = require("todo-comments")
                local function shallowcopy(orig)
                  local orig_type = type(orig)
                  local copy
                  if orig_type == 'table' then
                     copy = {}
                     for orig_key, orig_value in pairs(orig) do
                         copy[orig_key] = orig_value
                     end
                  else -- number, string, boolean, etc
                       copy = orig
                  end
                  return copy
                end

                tc.setup()

                local levelMap = {
                    -- Three level urgency system
                    ["Info"] = { "Todo", "Note" },
                    ["Warn"] = { "Warn", "Perf", "Test" },
                    ["Error"] = { "Fix", "Hack" }
                }

                -- override the links
                for key in pairs(levelMap) do
                    local diagnosticHlGroup = 'Diagnostic' .. key -- -> 'DiagnosticInfo', etc.

                    for _, todoCommentsGroup in ipairs(levelMap[key]) do
                        local groupText = vim.api.nvim_get_hl(0, { name = diagnosticHlGroup })
                        groupText["italic"] = true -- to separate from normal comments
                        local groupBadge = shallowcopy(groupText)
                        groupBadge["reverse"] = true

                        -- first the sign
                        vim.api.nvim_set_hl(0, 'TodoSign' .. todoCommentsGroup, { link = diagnosticHlGroup })
                        vim.api.nvim_set_hl(0, 'TodoFg' .. todoCommentsGroup, groupText)
                        vim.api.nvim_set_hl(0, 'TodoBg' .. todoCommentsGroup, groupBadge)
                    end
                end

                -- clear treesitter's comment highlight
                vim.api.nvim_set_hl(0, 'Todo', {})

                vim.keymap.set("n", "]t", function()
                  tc.jump_next()
                end, { desc = "Next todo comment" })

                vim.keymap.set("n", "[t", function()
                  tc.jump_prev()
                end, { desc = "Previous todo comment" })

                require("which-key").register({
                  t = {
                    t = { ":TodoTelescope<CR>", "Telescope with todos" }
                  },
                }, { prefix = "<leader>" })
              '';
          }
          pkgs.vimPlugins.nvim-web-devicons
          {
            plugin = pkgs.vimPlugins.telescope-file-browser-nvim;
            type = "lua";
            config =
              # lua
              ''
                require("telescope").load_extension "file_browser"
                require("which-key").register({
                  F = {
                    f = { require'telescope'.extensions.file_browser.file_browser, "Find files on filesystem" }
                  },
                }, { prefix = "<leader>" })
              '';
          }
          {
            plugin = pkgs.vimPlugins.telescope-nvim;
            type = "lua";
            config =
              # lua
              ''
                local telescope = require('telescope')
                telescope.setup()

                local wk = require("which-key")
                wk.register({
                  ["<leader>"] = { require'telescope.builtin'.find_files, "Find files" },
                  ["b"] = { require'telescope.builtin'.buffers, "Buffers" },
                  ["/"] = { require'telescope.builtin'.live_grep, "Live grep" },
                  F = {
                    r = { require'telescope.builtin'.oldfiles, "Open recent files" }
                  },
                }, { prefix = "<leader>" })
              '';
          }
          {
            plugin = pkgs.vimPlugins.hop-nvim;
            type = "lua";
            config = # lua
              ''
                local hop = require('hop')
                hop.setup()
                local wk = require("which-key")

                wk.register({
                  j = { ":HopWord<CR>", "Jump" }
                }, { prefix = "<leader>" })
              '';
          }
          {
            plugin = pkgs.vimPlugins.which-key-nvim;
            type = "lua";
            config =
              # lua
              ''
                vim.o.timeout = true
                vim.o.timeoutlen = 300
                local wk = require("which-key")

                wk.register({
                  w = {
                    name = "window",
                    s = { ":split<CR>", "Split horizontally" },
                    v = { ":vsplit<CR>", "Split vertically" },
                    d = { "<C-w>c", "Close window" },
                    h = { "<C-w>h", "Focus left" },
                    j = { "<C-w>j", "Focus bottom" },
                    k = { "<C-w>k", "Focus up" },
                    l = { "<C-w>l", "Focus right" }
                  },
                }, { prefix = "<leader>" })
              '';
          }
          {
            plugin = pkgs.vimPlugins.nvim-cmp;
            type = "lua";
            config =
              # lua
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
                    ["<Tab>"] = cmp.mapping(function(fallback)
                    -- source: https://www.reddit.com/r/neovim/comments/yiimig/cmp_luasnip_jump_points_strange_behaviour/
                      local ls = require("luasnip")
                      if cmp.visible() then
                        cmp.confirm { select = true }
                      elseif ls.expand_or_locally_jumpable() then
                        ls.expand_or_jump()
                      else
                        fallback()
                      end
                      end, {
                           "i",
                           "s",
                       }),
                  },
                  sources = cmp.config.sources({
                    ${if cfg.enableLangServers
                      then
                        ''
                          { name = 'luasnip' },
                          { name = 'nvim_lsp' },
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
          {
            plugin = pkgs.vimPlugins.luasnip;
            type = "lua";
            config =
              # lua
              ''
                local ls = require("luasnip")
                -- some shorthands...
                local s = ls.snippet
                local sn = ls.snippet_node
                local t = ls.text_node
                local i = ls.insert_node
                local f = ls.function_node
                local c = ls.choice_node
                local d = ls.dynamic_node
                local r = ls.restore_node
                local l = require("luasnip.extras").lambda
                local rep = require("luasnip.extras").rep
                local p = require("luasnip.extras").partial
                local m = require("luasnip.extras").match
                local n = require("luasnip.extras").nonempty
                local dl = require("luasnip.extras").dynamic_lambda
                local fmt = require("luasnip.extras.fmt").fmt
                local fmta = require("luasnip.extras.fmt").fmta
                local types = require("luasnip.util.types")
                local conds = require("luasnip.extras.conditions")
                local conds_expand = require("luasnip.extras.conditions.expand")

                ls.setup({
                    history = true,
                    -- Update more often, :h events for more info.
                    update_events = "TextChanged,TextChangedI",
                    -- Snippets aren't automatically removed if their text is deleted.
                    -- `delete_check_events` determines on which events (:h events) a check for
                    -- deleted snippets is performed.
                    -- This can be especially useful when `history` is enabled.
                    delete_check_events = "TextChanged",
                    ext_opts = {
                        [types.choiceNode] = {
                            active = {
                                virt_text = { { "choiceNode", "Comment" } },
                            },
                        },
                    },
                    -- treesitter-hl has 100, use something higher (default is 200).
                    ext_base_prio = 300,
                    -- minimal increase in priority.
                    ext_prio_increase = 1,
                    enable_autosnippets = true,
                    -- mapping for cutting selected text so it's usable as SELECT_DEDENT,
                    -- SELECT_RAW or TM_SELECTED_TEXT (mapped via xmap).
                    store_selection_keys = "<Tab>",
                    -- luasnip uses this function to get the currently active filetype. This
                    -- is the (rather uninteresting) default, but it's possible to use
                    -- eg. treesitter for getting the current filetype by setting ft_func to
                    -- require("luasnip.extras.filetype_functions").from_cursor (requires
                    -- `nvim-treesitter/nvim-treesitter`). This allows correctly resolving
                    -- the current filetype in eg. a markdown-code block or `vim.cmd()`.
                    ft_func = function()
                        return vim.split(vim.bo.filetype, ".", true)
                    end,
                })
                ls.config.set_config({
                  region_check_events = 'InsertEnter',
                  delete_check_events = 'InsertLeave'
                });

                ls.add_snippets("nix", {
                    -- "Let .. in" template
                    s("let", {
                        -- Instead of a linebreak, tab by hand
                        t({ "let", "\t" }),
                        i(1),
                        t({ "", "in" }),
                    }),
                    s("if", {
                        t({ "if " }),
                        i(1),
                        t({ " then " }),
                        i(2),
                        t({ " else " }),
                        i(3),
                        t({ ";" }),
                    }),

                }, {
                    key = "nix",
                })
                ls.add_snippets("nickel", {
                    -- "Let .. in" template
                    s("let", {
                        -- Instead of a linebreak, tab by hand
                        t({ "let", "\t" }),
                        i(1),
                        t({ "", "in" }),
                    }),
                }, {
                    key = "nickel",
                })

                -- set type to "autosnippets" for adding autotriggered snippets.
                ls.add_snippets("all", {
                    s("autotrigger", {
                        t("autosnippet"),
                    }),
                }, {
                    type = "autosnippets",
                    key = "all_auto",
                })

              '';
          }
          pkgs.vimPlugins.cmp-buffer
          pkgs.vimPlugins.cmp-cmdline
          pkgs.vimPlugins.cmp-path
          pkgs.vimPlugins.luasnip
          pkgs.vimPlugins.cmp_luasnip
          {
            plugin = scratch-plugin;
            type = "lua";
            config =
              # lua
              ''
                -- Open scratch from bottom side
                vim.g["scratch_top"] = 0
                -- Disable default mappings
                vim.g["scratch_no_mappings"] = 1
                -- Disable autohide
                vim.g["scratch_autohide"] = 0

                local wk = require("which-key")
                wk.register({
                  x = { ":Scratch<CR>", "Open scratch"}
                }, { prefix = "<leader>" })
              '';
          }
        ]
        ++
        (
          if cfg.enableLangServers
          then
            [
              {
                plugin = stable-plugins.neodev-nvim;
                type = "lua";
                config =
                  # lua
                  ''
                    require("neodev").setup({})'';
              }
              pkgs.vimPlugins.cmp-nvim-lsp
              {
                plugin = pkgs.vimPlugins.nvim-treesitter;
                type = "lua";
                config =
                  # lua
                  ''
                    local configs = require 'nvim-treesitter.configs';
                    configs.setup {
                    highlight = { enable = true },
                    }
                  '';
              }
              pkgs.vimPlugins.nvim-treesitter-parsers.nix
              pkgs.vimPlugins.nvim-treesitter-parsers.rust
              pkgs.vimPlugins.nvim-treesitter-parsers.bash
              pkgs.vimPlugins.nvim-treesitter-parsers.lua
              pkgs.vimPlugins.nvim-treesitter-parsers.sql
              pkgs.vimPlugins.nvim-treesitter-parsers.markdown
              pkgs.vimPlugins.nvim-treesitter-parsers.yaml
              pkgs.vimPlugins.nvim-treesitter-parsers.python
              pkgs.vimPlugins.nvim-treesitter-parsers.json
              pkgs.vimPlugins.nvim-treesitter-parsers.ini
              pkgs.vimPlugins.nvim-treesitter-parsers.toml
              pkgs-unstable.vimPlugins.nvim-treesitter-parsers.nickel
              hmts
              {
                plugin = pkgs.vimPlugins.fidget-nvim;
                type = "lua";
                config = /* lua */ "require('fidget').setup {}";
              }
              {
                plugin = pkgs.vimPlugins.nvim-lspconfig;
                type = "lua";
                config =
                  # lua
                  ''
                    local wk = require("which-key")

                    wk.register({
                      s = { vim.lsp.buf.signature_help, "See signature help"},
                      h = { vim.lsp.buf.hover, "Trigger hover"},
                      d = { vim.diagnostic.open_float, "Show diagnostics in a floating window."},
                      q = { vim.diagnostic.setloclist, "Add buffer diagnostics to the location list"},
                      r = { vim.lsp.buf.rename, "LSP rename"},
                      a = { vim.lsp.buf.code_action, "LSP code actions"},
                      f = { vim.lsp.buf.format, "LSP format"}
                    }, { prefix = "<leader>" })

                    wk.register({
                      ["gD"] = { vim.lsp.buf.declaration, "Go to declaration"},
                      ["gd"] = { vim.lsp.buf.definition, "Go to definition"},
                      ["gi"] = { vim.lsp.buf.implementation, "Go to implementation"},
                      ["gr"] = { vim.lsp.buf.references, "Go to references"},
                      ["[d"] = { vim.diagnostic.goto_prev, "Previous diagnostic"},
                      ["]d"] = { vim.diagnostic.goto_next, "Next diagnostic"},
                    })

                    --vim.keymap.set('x', '\\a', function() vim.lsp.buf.code_action() end)

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
                    require('lspconfig').nickel_ls.setup {
                      autostart = true,
                      cmd = { '${lib.getExe pkgs-unstable.nls}' },
                    }
                    require('lspconfig').lua_ls.setup {
                      autostart = true,
                      capabilities = caps,
                      Lua = { completion = { callSnippet = "Replace" } } -- Needed by neodev-vim
                    }
                  '';
              }
            ]
          else [ ]
        );
      extraLuaConfig =
        # lua
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
          -- Automatically resize splits when window size changes
          vim.api.nvim_create_autocmd('VimResized', {
            command = 'wincmd =',
            pattern = '*',
          })
          KITTY_SCROLLBACK = function(INPUT_LINE_NUMBER, CURSOR_LINE, CURSOR_COLUMN)
            vim.opt.encoding='utf-8'
            vim.opt.compatible = false
            -- Looks like this is needed to not wrap end lines?
            vim.opt.number = false
            vim.opt.relativenumber = false
            vim.opt.termguicolors = true
            vim.opt.showmode = false
            vim.opt.ruler = false
            vim.opt.laststatus = 0
            vim.opt.showcmd = false
            vim.opt.scrollback = 1000
            local term_buf = vim.api.nvim_create_buf(true, false);
            local term_io = vim.api.nvim_open_term(term_buf, {})
            vim.api.nvim_buf_set_keymap(term_buf, 'n', 'q', '<Cmd>q<CR>', { })
            local group = vim.api.nvim_create_augroup('kitty+page', {})

            vim.api.nvim_create_autocmd('ModeChanged', {
              group = group,
              buffer = term_buf,
              command = 'stopinsert'
            })

            vim.api.nvim_create_autocmd('VimEnter', {
              group = group,
              pattern = '*',
              once = true,
              callback = function(ev)
                  local current_win = vim.fn.win_getid()
                  for _, line in ipairs(vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false)) do
                    vim.api.nvim_chan_send(term_io, line)
                    vim.api.nvim_chan_send(term_io, '\r\n')
                  end
                  print('kitty sent:', INPUT_LINE_NUMBER, CURSOR_LINE, CURSOR_COLUMN)
                  term_io = false
                  vim.api.nvim_win_set_buf(current_win, term_buf)
                  vim.api.nvim_buf_delete(ev.buf, { force = true } )
              end
            })
          end
        '';
      extraConfig =
        # vim
        ''
          syntax on

          let mapleader="\<Space>"

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
          " set comments to be distinct from strings
          hi Comment ctermfg=5

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
