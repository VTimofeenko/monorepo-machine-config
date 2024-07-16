{ lib, ... }:
let
  inherit (lib) pipe listToAttrs;
in
{
  arrowKeys = {
    H = "l";
    J = "d";
    K = "u";
    L = "r";
  };
  Shift = "SHIFT";
  Super = "SUPER";
  Control = "CTRL";

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
}
