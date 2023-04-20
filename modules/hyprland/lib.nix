rec {
  shift = "SHIFT";
  ctrl = "CTRL";
  alt = "ALT";
  _mkBinding = mods: k: v: "bind = ${mods}, ${k}, ${v}";
  mkMainModBinding = _mkBinding "$mainMod";
  mkMainModShiftBinding = _mkBinding "$mainMod ${shift}";
  mkMainModCtrlBinding = _mkBinding "$mainMod ${ctrl}";
  mkMainModAltBinding = _mkBinding "$mainMod ${ctrl}";
}
