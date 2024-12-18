/**
  Window control:
  - Resize
  - Kill
  - Toggle floating
  - etc.
*/
{ srvLib, ... }:
let
  settings = {
    smallStep = 10;
    bigStep = 50;
    smallToBigKeyboardButton = Shift;
  };

  inherit (settings) smallStep smallToBigKeyboardButton bigStep;
  inherit (srvLib)
    arrowKeys
    Control
    Shift
    lib
    mainMod
    ;

  inherit (arrowKeys)
    left
    down
    up
    right
    ;
in
{
  # The resize mode
  "${Control}+R" =
    let
      transforms = {
        "${left}" = [
          "-${toString smallStep} 0"
          "horizontally"
          "left"
          smallStep
        ];
        "${right}" = [
          "${toString smallStep} 0"
          "horizontally"
          "right"
          smallStep
        ];
        "${up}" = [
          "0 ${toString smallStep}"
          "vertically"
          "up"
          smallStep
        ];
        "${down}" = [
          "0 -${toString smallStep}"
          "vertically"
          "down"
          smallStep
        ];
      };

      transformsFinal =
        # add the modifier to the keys
        # this is done in the attrname so that the later update does not overwrite the keys
        transforms
        |> lib.mapAttrs' (n: v: lib.nameValuePair ("${smallToBigKeyboardButton}+${n}") v)
        # Change the small step to the big step
        |> lib.mapAttrs (
          _: v:
          let
            # These functions will be applied to the value at the corresponding positions
            funcs = [
              # Replace smallStep with bigStep
              (lib.replaceStrings [ (toString smallStep) ] [ (toString bigStep) ])
              # leave type as is
              lib.id
              # leave direction as is
              lib.id
              # replace with bigstep
              (_: bigStep)
            ];
          in
          v
          # Produce a list of attrsets with fst = func, snd = value from v
          |> lib.lists.zipLists funcs
          # Apply func (fst) to values (fst), end up with a list
          |> (map (x: x.fst x.snd))
        )
        |> lib.mergeAttrs transforms;
    in
    {
      mod = mainMod;
      arg = "resize";
      description = "resize mode";
    }
    // (
      # Adjust transformsFinal to the needed shape
      transformsFinal
      |> lib.mapAttrs (
        _: v:
        let
          arg = lib.elemAt v 0;
          type = lib.elemAt v 1;
          direction = lib.elemAt v 2;
          step = lib.elemAt v 3;
        in
        {
          dispatcher = "resizeactive";
          flags = [ "e" ]; # e is for rEpeatable
          inherit arg;
          description = "Move the split ${type} to the ${direction} by ${toString step}";
        }
      )
    );

  # TODO: make window float
  # TODO: window fullscreen/focus
  # TODO: move to scratch?
}
