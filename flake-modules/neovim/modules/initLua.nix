{ pkgs, lib }:
lib.concatMapStringsSep "\n" builtins.readFile [
  ./configs/init/base.lua
  ./configs/init/file-specific.lua
  ./configs/init/kitty-scrollback-override.lua
]
+ ''
  vim.opt.clipboard = 'unnamed${if pkgs.stdenv.isLinux then "plus" else ""}'
''
