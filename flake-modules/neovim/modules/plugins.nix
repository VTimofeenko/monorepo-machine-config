# Main file where all plugins are configured
{
  pkgs,
  inputs,
  withLangServers ? false,
  extraPlugins ? [ ],
}:
let
  common =
    builtins.attrValues {
      inherit (vimPlugins)
        vim-surround # helps managing surrounding brackets/html tags/etc.
        vim-commentary # file syntax-aware comments toggling
        delimitMate # auto-close brackets in insert mode
        vim-strip-trailing-whitespace # trims whitespace
        nvim-web-devicons # icons, auto detected by telescope
        vim-nftables # nftables language support. Needed outside language support for stripped down nvim on some machines
        cmp-buffer # Buffer completions
        cmp-cmdline # Completions for cmdline
        cmp-path # Path completion
        cmp_luasnip # Completions for snippets
        ;
    }
    # Plugins with additional configuration
    ++ [
      [
        vimPlugins.which-key-nvim
        ./configs/which-key.lua
      ]
      [
        vimPlugins.hop-nvim # Allows quickly jumping around the file
        ./configs/hop.lua
      ]
      [
        (mkPluginFromInput "vim-scratch-plugin") # scratch buffer
        ./configs/scratch.lua
      ]
      [
        vimPlugins.todo-comments-nvim # Provides nice parsed TODO badges inline
        ./configs/todo-comments.lua
      ]
      [
        vimPlugins.luasnip
        ./configs/luasnip.lua
      ]
      [
        vimPlugins.telescope-nvim
        ./configs/telescope.lua
      ]
      [
        vimPlugins.telescope-file-browser-nvim
        ./configs/telescope-file-browser.lua
      ]
      [
        pkgs.vimPlugins.nvim-cmp
        ./configs/cmp.lua # TODO: lang-server specific completion
      ]
    ];

  langServerPlugins =
    builtins.attrValues {
      inherit (vimPlugins)
        cmp-nvim-lsp # completions from LSP
        hmts-nvim # highlights inside strings in Nix
        vim-nickel
        vim-nix # Needed at least for builtins. completions
        ;
      inherit (vimPlugins.nvim-treesitter) withAllGrammars;
    }
    ++ [
      [
        vimPlugins.nvim-treesitter # Treesitter itself
        "require('nvim-treesitter.configs').setup { highlight = { enable = true }, }"
      ]
      [
        vimPlugins.fidget-nvim # UI for LSP
        "require('fidget').setup {}"
      ]
      [
        vimPlugins.neodev-nvim
        "require('neodev').setup({})" # TODO: there was something more
      ]
      [
        vimPlugins.nvim-lspconfig # Helper for configuring LSP connections
        ./configs/lspconfig.lua
      ]
      [
        vimPlugins.nvim-treesitter-context # Adds LSP context on the top
        ./configs/treesitter-context.lua
      ]
      [
        vimPlugins.nvim-ufo
        ./configs/ufo.lua
      ]
      # [
      #   (mkPluginFromInput "nvim-devdocs") # devdocs.io inside nvim # TODO: pre-install the docs
      #   ./configs/devdocs.lua
      # ]
      [
        vimPlugins.nvim-colorizer-lua
        ./configs/colorizer.lua
      ]
      [
        vimPlugins.gitsigns-nvim
        ./configs/gitsigns.lua
      ]
      [
        vimPlugins.trouble-nvim
        ./configs/trouble-nvim.lua
      ]
    ];

  inherit (pkgs) vimPlugins;

  /*
    Takes a list of plugins and transforms it for downstream compatibility

    If an element is just a derivation -- turn it into attrset with  single "pkg" element and empty "config"

    If an element is a list, turn it into an attrset:
      1. Take the first element, use it for "pkg" attribute
      2. Take the second element, put it into "config" attribute:
        - If it's a path -- read the file
        - If it's a string -- leave as is
  */
  normalizePlugin =
    plugin:
    if lib.attrsets.isDerivation plugin then
      {
        pkg = plugin;
        config = "";
      }
    else if lib.isList plugin then
      let
        configPart = lib.last plugin;
      in
      {
        pkg = lib.head plugin;
        config =
          if lib.isPath configPart then
            builtins.readFile configPart
          else if lib.isString configPart then
            configPart
          else
            builtins.abort "Not sure how to parse ${configPart}";
      }
    else
      builtins.abort "Not sure what to do with ${plugin}";

  /*
    Create a plugin from input using the bound instance of `pkgs`.

    Example: mkPluginFromInput input-flake -> derivation
  */
  mkPluginFromInput =
    inputPlugin:
    pkgs.vimUtils.buildVimPlugin {
      name = inputPlugin;
      src = inputs.${inputPlugin};
    };

  inherit (pkgs) lib;
in
{
  plugins = map normalizePlugin (
    common ++ (if withLangServers then langServerPlugins else [ ]) ++ extraPlugins
  );
}
