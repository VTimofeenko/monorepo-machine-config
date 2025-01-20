{ pkgs, lib, ... }:
{
  plugin = pkgs.vimPlugins.luasnip;

  config =
    [
      # Common intro
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
          region_check_events = "InsertEnter",
          delete_check_events = "InsertLeave",
        })
      ''
      # Auto-trigger snippets
      ''
        -- set type to "autosnippets" for adding autotriggered snippets.
        ls.add_snippets("all", {
          s("autotrigger", {
            t("autosnippet"),
          }),
        }, {
          type = "autosnippets",
          key = "all_auto",
        })
      ''
      # Completions setup.
      # <tab> is used to either complete the completion or to skip through the placeholders in the template
      ''
        -- Prepend to the table to show luasnip early
        table.insert(cmp_sources, 1, { name = "luasnip" })
        cmp_mappings["<Tab>"] = cmp.mapping(function(fallback)
            -- source: https://www.reddit.com/r/neovim/comments/yiimig/cmp_luasnip_jump_points_strange_behaviour/
            local ls = require("luasnip")
            if cmp.visible() then
              cmp.confirm({ select = true })
            elseif ls.expand_or_locally_jumpable() then
              ls.expand_or_jump()
            else
              fallback()
            end
          end, {
            "i",
            "s",
        })
        cmp_snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        }
      ''
    ];
}
