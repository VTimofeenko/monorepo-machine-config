/**
  General in-buffer image viewing via `image.nvim`, mainly for Markdown
  image links. Press over/near a `![]()` link and it renders inline.
*/
{ pkgs, ... }:
{
  plugin = pkgs.vimPlugins.image-nvim;

  extraPackages = [
    pkgs.imagemagick # image.nvim's default processor shells out to `magick`/`convert`
  ];

  config =
    # lua
    ''
      require("image").setup({
        integrations = {
          markdown = { enabled = true },
        },
      })
    '';
}
