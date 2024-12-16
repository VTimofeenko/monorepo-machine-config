{ srvLib, ... }:
let
  inherit (srvLib) mainMod arrowKeys Shift;
in
[
  "left"
  "down"
  "up"
  "right"
]
|> map (x: {
  name = "${Shift}+${arrowKeys.${x}}";
  value = {
    mod = mainMod;
    dispatcher = "movewindow";
    arg = arrowKeys.${arrowKeys.${x}};
    description = "move window to the split to the ${x}";
  };
})
|> builtins.listToAttrs
