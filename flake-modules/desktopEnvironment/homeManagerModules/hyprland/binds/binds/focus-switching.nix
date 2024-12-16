{ srvLib, ... }:
let
  inherit (srvLib) mainMod arrowKeys;
in
[
  "left"
  "down"
  "up"
  "right"
]
|> map (x: {
  name = arrowKeys."${x}";
  value = {
    mod = mainMod;
    dispatcher = "movefocus";
    arg = arrowKeys.${arrowKeys.${x}};
    description = "focus to the ${x}";
  };
})
|> builtins.listToAttrs
