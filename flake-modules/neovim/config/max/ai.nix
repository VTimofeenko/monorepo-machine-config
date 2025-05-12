/**
  Simple aider setup in neovim. Needs passing the API key in the environment.
*/
{
  pkgs-unstable,
  ...
}:
let
  settings.aiderCmdArgs = [
    "--no-auto-commits"
    "--model gemini/gemini-2.0-flash"
    "--no-show-model-warnings"
    # Aider is managed declaratively, there's no need for the update-related things
    "--no-check-update"
    "--no-show-release-notes"
  ];
in
{
  plugin = pkgs-unstable.vimPlugins.aider-nvim;
  config =
    # lua
    ''
        require('aider').setup({
        auto_manage_context = false,
        default_bindings = true,
        debug = true,
        wk.add({
          {
            "<leader>Z",
            function()
              local handle = io.popen("pass show notes/gemini-api-key", "r")
              vim.env["GEMINI_API_KEY"] = handle:read("*l")
              handle:close()
              --vim.notify(vim["GEMINI_API_KEY"])

              require("aider").AiderOpen("${settings.aiderCmdArgs |> builtins.concatStringsSep " "}")
            end,
            desc = "AI",
          }
        })
      })
    '';
}
