{ srvLib, ... }:
let
  appMap = {
    # E is for Emacs
    e = "Emacs";
  };
  inherit (srvLib) lib Hyper mainMod;
in
lib.mapAttrs' (
  name: value:
  lib.nameValuePair "${Hyper}+${name}" {
    mod = mainMod;
    dispatcher = "focuswindow";
    arg = "^(Emacs)$";
    description = "Focus ${value} window";
  }
) appMap
