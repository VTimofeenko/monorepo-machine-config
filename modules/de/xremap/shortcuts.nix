# [[file:../../../new_project.org::*Xremap shortcuts][Xremap shortcuts:1]]
{ pkgs, lib, config, ... }@inputs:
let
  consoleLikeApps = [ "kitty" "Emacs" "kitty-dropterm" ];
in
{
  services.xremap.config = {
    modmap = [
      {
        # Global remap CapsLock to Esc
        name = "Global";
        remap = { "CapsLock" = "Esc"; };
      }
    ];
    keymap = [
      {
        name = "Bypass remaps";
        remap = { "CTRL_L-SHIFT-ESC" = { escape_next_key = true; }; };
      }
      {
        name = "Emacs-like shortcuts";
        exact_match = true;
        application =
          {
            "not" = consoleLikeApps;
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
            "not" = consoleLikeApps;
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
            "only" = consoleLikeApps;
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
      {
        # Easier to press with a thumb
        name = "Remap alt-backspace to ctrl-backspace";
        remap = { "ALT-Backspace" = "C-Backspace"; };
      }
    ];
  };
}
# Xremap shortcuts:1 ends here
