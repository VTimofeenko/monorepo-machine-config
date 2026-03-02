{ pkgs, ... }:
{
  plugins = [
    pkgs.vimPlugins.telescope-nvim
    pkgs.vimPlugins.telescope-file-browser-nvim
    pkgs.vimPlugins.nvim-web-devicons
  ];

  config =
    ''
      local wk = require("which-key")
      wk.add({
        {
          "<leader>/",
          function()
            require("telescope.builtin").live_grep({ glob_pattern = "!*.lock" })
          end,
          desc = "Live grep",
        },
        {
          "<leader><leader>",
          function()
            require("telescope.builtin").find_files({ cwd = vim.env.PRJ_ROOT, path_display = { "truncate" } })
          end,
          desc = "Find files in project",
        },
        {
          "<leader>?",
          function()
            require("telescope.builtin").live_grep({ glob_pattern = "!*.lock", cwd = vim.fn.expand("%:h") })
          end,
          desc = "Live grep look around",
        },
        {
          "<leader>fr",
          require("telescope.builtin").oldfiles,
          desc = "Open recent files",
        },
        {
          "<leader>l",
          function()
            require("telescope.builtin").find_files({ cwd = vim.fn.expand("%:h") })
          end,
          desc = "Look around in the current dir",
        },
      })
    ''
    # lua
    + ''
      require("telescope").load_extension("file_browser")

      local file_browser = require("telescope").extensions.file_browser.file_browser

      wk.add({
        { "<leader>ff", file_browser, desc = "File browser in project root" },
        {
          "<leader>fl",
          function()
            file_browser({ cwd = vim.fn.expand("%:h") })
          end,
          desc = "File browser (look around)",
        },
        { "<leader>bb", require("telescope.builtin").buffers, desc = "Buffer selector" },
      })

    '';
}
