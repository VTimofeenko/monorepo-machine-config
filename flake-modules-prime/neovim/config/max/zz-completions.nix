/**
  File name should ensure that it's loaded last
*/
{ pkgs, ... }:
{
  plugins = [
    pkgs.vimPlugins.cmp_luasnip
  ];
  config = ''
      cmp.setup({
        snippet = cmp_snippet,
        sources = cmp.config.sources(cmp_sources),
        mapping = cmp_mappings,
      })
  '';
}
