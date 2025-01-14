{ pkgs, ... }:
{
  plugins = [
    pkgs.vimPlugins.nvim-cmp
    pkgs.vimPlugins.cmp-buffer
    pkgs.vimPlugins.cmp-path
    pkgs.vimPlugins.cmp-cmdline
  ];
  config =
    # lua
    ''
      local cmp = require("cmp")
      cmp_sources = {
        { name = "path" },
        { name = "buffer" },
      }
      cmp_mappings = {
        ["<C-p>"] = cmp.mapping.select_prev_item(),
        ["<C-n>"] = cmp.mapping.select_next_item(),
        ["<C-space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.close(),
      }

      cmp.setup.cmdline("/", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
      })

      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          {
            name = "cmdline",
            option = {
              ignore_cmds = { "Man", "!" },
            },
          },
        }),
      })

      cmp.setup({
        sources = cmp.config.sources(cmp_sources),
        mapping = cmp_mappings,
      })
    '';
}
