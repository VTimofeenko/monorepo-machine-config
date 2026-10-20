# config.kdl plus the lines that need Nix store paths
builtins.readFile ./config.kdl
+ ''
  // -S sources the script after zellij's dump file is opened
  scrollback_editor "nvim -S ${./scrollback.lua}"
''
