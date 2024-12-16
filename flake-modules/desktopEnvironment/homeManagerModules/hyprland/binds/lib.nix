{ lib, ... }:
let
  inherit (lib) pipe listToAttrs;
in
rec {
  arrowKeys = {
    left = "H";
    down = "J";
    up = "K";
    right = "L";

    H = "l";
    J = "d";
    K = "u";
    L = "r";
  };
  Shift = "SHIFT";
  Super = "SUPER";
  Control = "CTRL";
  Alt = "ALT";
  Meta = Alt;
  Hyper = "${Shift}+${Control}+${Alt}";

  "`" = "grave";

  LMB = "mouse:272";
  RMB = "mouse:273";
  mainMod = "$mainMod";

  mkOneToTen =
    pipe (lib.genList (x: x + 1) 9) # [ 1 .. 9]
      [
        (map (x: {
          name = x;
          value = x;
        }))
        listToAttrs
      ];

  # Reexport lib for easier consumption by downstram
  # modules
  inherit lib;
}
