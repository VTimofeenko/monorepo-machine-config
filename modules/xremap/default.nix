{ pkgs, config, lib, ... }:
{
  services.xremap =
    {
      withHypr = true;
      userName = "spacecadet";
      serviceMode = "user";
      config =
        {
          modmap =
            [
              {
                # Global remap CapsLock to Esc
                name = "Global";
                remap = { "CapsLock" = "Esc"; };
              }
            ];
          keymap =
            [
              {
                name = "Bypass remaps";
                remap = { "CTRL_L-SHIFT-ESC" = { escape_next_key = true; }; };
              }
              {
                name = "Emacs-like shortcuts";
                application =
                  {
                    "not" =
                      [
                        "kitty"
                        "Emacs"
                      ];
                  };
                remap =
                  {
                    "CTRL_L-a" = "home";
                    "CTRL_L-e" = "end";
                    # Same, but select
                    "CTRL_L-Shift-a" = "Shift-home";
                    "CTRL_L-Shift-e" = "Shift-end";
                    "CTRL_L-W" = "C-Backspace";
                  };
              }
              {
                name = "Global shortcuts";
                application =
                  {
                    "not" =
                      [
                        "kitty"
                        "Emacs"
                      ];
                  };
                remap =
                  {
                    # Select all
                    "SUPER-a" = "C-a";
                    # Copy
                    "SUPER-c" = "C-c";
                    # Cut
                    "SUPER-x" = "C-x";
                    # Undo
                    "SUPER-z" = "C-z";
                    # Paste
                    "SUPER-v" = "Shift-insert";
                    # Generic "close thing"
                    "SUPER-w" = "C-w";
                  };
              }
              {
                name = "Global-like shortcuts for terminal and emacs";
                application =
                  {
                    "only" =
                      [
                        "kitty"
                        "Emacs"
                      ];
                  };
                remap =
                  {
                    # Copy
                    "SUPER-c" = "C-Shift-c";
                    # Paste
                    "SUPER-v" = "Shift-insert";
                  };
              }
              {
                name = "Close stuff by super-w";
                application =
                  {
                    "only" =
                      [
                        "firefox"
                        "brave-browser"
                      ];
                  };
                remap =
                  {
                    "SUPER-w" = "C-w";
                    "SUPER-SHIFT-w" = "C-Shift-w";
                    "SUPER-t" = "C-t";
                    "SUPER-SHIFT-t" = "C-Shift-t";
                  };
              }
              {
                name = "Brave set incognito to a sane shortcut";
                application = { "only" = "brave-browser"; };
                remap =
                  {
                    "C-Shift-p" = "C-Shift-n";
                  };
              }
            ];
        };
    };
}
