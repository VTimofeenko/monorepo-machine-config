# Main file where all plugins are configured
{ pkgs, inputs }:
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
        ./plugins-config/which-key.lua
      ]
      [
        vimPlugins.hop-nvim # Allows quickly jumping around the file
        ./plugins-config/hop.lua
      ]
      [
        (mkPluginFromInput "vim-scratch-plugin") # scratch buffer
        ./plugins-config/scratch.lua
      ]
      [
        vimPlugins.todo-comments-nvim # Provides nice parsed TODO badges inline
        ./plugins-config/todo-comments.lua
      ]
      [
        vimPlugins.luasnip
        ./plugins-config/luasnip.lua
      ]
      [
        vimPlugins.telescope-nvim
        ./plugins-config/telescope.lua
      ]
      [
        vimPlugins.telescope-file-browser-nvim
        ./plugins-config/telescope-file-browser.lua
      ]
      [
        pkgs.vimPlugins.nvim-cmp
        ./plugins-config/cmp.lua # TODO: lang-server specific completion
      ]
    ];

  inherit (pkgs) vimPlugins;

  /* Takes a list of plugins and transforms it for downstream compatibility

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

  mkPluginFromInput =
    inputPlugin:
    pkgs.vimUtils.buildVimPlugin {
      name = inputPlugin;
      src = inputs.${inputPlugin};
    };

  inherit (pkgs) lib;
in
{
  plugins = map normalizePlugin common;
}
