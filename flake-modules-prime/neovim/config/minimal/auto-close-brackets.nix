/**
  Configures automatic closing of parentheses, brackets, quotation marks.

  I use nvim-autopairs since it works well with nix's multiline ''strings'' as well as markdown's ```codeblock```.

  Other plugins considered:

  - delimitmate
  - autoclose.nvim
*/
{ pkgs, ... }:
{
  plugin = pkgs.vimPlugins.nvim-autopairs;
  config = ''
    require("nvim-autopairs").setup({ })
  '';
}
