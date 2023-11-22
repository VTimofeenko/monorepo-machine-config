# Kinda modeled after home-manager's neovim module
{ pkgs
, inputs
, enableLangServers ? false
, ...
}:
let
  # TODO: add 1. enter -> 2. for markdown

  # Common plugins with no upfront configuration required.
  commonPlugins = builtins.attrValues {
    inherit (pkgs.vimPlugins)
      vim-surround# helps managing surrounding brackets/html tags/etc.
      vim-commentary# file syntax-aware comments toggling
      delimitMate# auto-close brackets in insert mode
      vim-strip-trailing-whitespace# trims whitespace
      nvim-web-devicons# icons, auto detected by telescope
      vim-nftables# nftables language support. Needed outside language support for stripped down nvim on some machines
      cmp-buffer# Buffer completions
      cmp-cmdline# Completions for cmdline
      cmp-path# Path completion
      cmp_luasnip# Completions for snippets
      ;
  };

  languageSpecificPlugins = {
    langCommonPlugins = builtins.attrValues {
      inherit (pkgs.vimPlugins)
        cmp-nvim-lsp# completions from LSP
        hmts-nvim# highlights inside strings in Nix
        vim-nickel
        vim-nix# Needed at least for builtins. completions
        ;
      inherit (pkgs.vimPlugins.nvim-treesitter) withAllGrammars;
    };
    langPlugins = [
      {
        pkg = pkgs.vimPlugins.nvim-treesitter; # Treesitter itself
        config = /* lua */ "require('nvim-treesitter.configs').setup { highlight = { enable = true }, }";
      }
      {
        pkg = pkgs.vimPlugins.fidget-nvim; # UI for LSP
        config = /* lua */ "require('fidget').setup {}";
      }
      {
        pkg = pkgs.vimPlugins.neodev-nvim;
        config = /* lua */ "require('neodev').setup({})"; # TODO: there was something more
      }
      {
        pkg = pkgs.vimPlugins.nvim-lspconfig; # Helper for configuring LSP connections
        config = builtins.readFile ./lua/lspconfig.lua;
      }
      {
        pkg = pkgs.vimPlugins.nvim-treesitter-context; # Adds LSP context on the top
        config = builtins.readFile ./lua/treesitter-context.lua;
      }
      {
        pkg = pkgs.vimPlugins.nvim-ufo; # Adds LSP folds
        config = builtins.readFile ./lua/ufo.lua;
      }
      {
        pkg = mkPluginFromInput "nvim-devdocs"; # devdocs.io inside nvim
        config = builtins.readFile ./lua/devdocs.lua;
      }
      {
        pkg = pkgs.vimPlugins.nvim-colorizer-lua;
        config = /* lua */ "require('colorizer').setup()";
      }
    ];
  };

  telescopePlugins = [
    {
      pkg = pkgs.vimPlugins.telescope-nvim;
      config =
        # lua
        ''
          local telescope = require('telescope')
          telescope.setup()

          local wk = require("which-key")
          wk.register({
            ["<leader>"] = { function() require'telescope.builtin'.find_files({cwd=vim.env.PRJ_ROOT, path_display = {"truncate"}}) end, "Find files in project" },
            l = { function() require'telescope.builtin'.find_files({cwd=vim.fn.expand('%:h')}) end, "Look around in the current dir" },
            ["b"] = { require'telescope.builtin'.buffers, "Buffers" },
            ["/"] = { function() require'telescope.builtin'.live_grep({glob_pattern = "!*.lock"}) end, "Live grep" },
            f = {
              r = { require'telescope.builtin'.oldfiles, "Open recent files" }
            },
          }, { prefix = "<leader>" })
        '';
    }
    {
      pkg = pkgs.vimPlugins.telescope-file-browser-nvim;
      config =
        # lua
        ''
          require("telescope").load_extension "file_browser"
          require("which-key").register({
            f = {
              f = { require'telescope'.extensions.file_browser.file_browser, "Find files on filesystem" }
            },
          }, { prefix = "<leader>" })
        '';
    }
  ];

  completionPlugins = [
    {
      pkg = pkgs.vimPlugins.nvim-cmp;
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
              ${if enableLangServers
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
  ];

  mkPluginFromInput = inputPlugin: pkgs.vimUtils.buildVimPlugin { name = inputPlugin; src = inputs.${inputPlugin}; };
  plugins =
    builtins.concatLists [
      commonPlugins
      [
        {
          pkg = pkgs.vimPlugins.which-key-nvim;
          config = builtins.readFile ./lua/which-key.lua;
        }
        {
          pkg = pkgs.vimPlugins.vim-easy-align; # Aligns text by pattern
          config =
            # lua
            ''
              vim.api.nvim_set_keymap("x", "ga", "<Plug>(EasyAlign)", {})'';
        }
        {
          # TODO: hop in visual mode
          pkg = pkgs.vimPlugins.hop-nvim;
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
          pkg = mkPluginFromInput "vim-scratch-plugin"; # Toggleable scratch window
          config = builtins.readFile ./lua/scratch.lua;
        }
        {
          pkg = pkgs.vimPlugins.todo-comments-nvim; # Provides nice parsed TODO badges inline
          config = builtins.readFile ./lua/todo-comments.lua;
        }
        {
          pkg = pkgs.vimPlugins.luasnip; # My snippets plugin
          config = builtins.readFile ./lua/luasnip.lua;
        }
      ]
      telescopePlugins
      completionPlugins
      (
        # If enabled -- add language specific packages
        if
          enableLangServers
        then
          (lib.lists.flatten (builtins.attrValues languageSpecificPlugins))
        else [ ]
      )
    ];

  inherit (inputs.nixpkgs-lib) lib;
  baseInit = builtins.readFile ./lua/init.lua +
    /* lua */ "vim.opt.clipboard = 'unnamed${if pkgs.stdenv.isLinux then "plus" else ""}'\n";

  additionalPkgs =
    # Common extra packages
    builtins.attrValues
      {
        inherit (pkgs)
          fd# Quick find replacement
          ripgrep# Quick grep replacement
          ;
      }
    ++
    # Language-dependant packages
    builtins.attrValues
      (if enableLangServers then
        {
          inherit (pkgs)
            nil# Nix lang server
            rnix-lsp# TODO: check if needed?
            rust-analyzer# Rust lang server
            nixpkgs-fmt# My default formatter
            nls# Nickel language server
            shellcheck# For shell files
            lua-language-server# For lua
            glow# for markdown previews
            stylua# for lua static checks
            ;
          inherit (pkgs.nodePackages)
            bash-language-server# Bash language server
            ;
        }
      else { });
  commonArgs = {
    inherit pkgs lib plugins baseInit additionalPkgs;
  };
in
import ./package-builder.nix commonArgs
