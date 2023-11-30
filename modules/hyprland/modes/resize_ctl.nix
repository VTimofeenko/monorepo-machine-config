# [[file:../../../new_project.org::*Resize_ctl][Resize_ctl:1]]
# TODO: rewrite this
mkModeBinding:
_:
mkModeBinding
  # Mode enter keybind
  "SUPERCTRL,R"
  # Mode name keybind
  "resize"
  ''
    # sets repeatable binds for resizing the active window
    binde=,h,resizeactive,10 0
    binde=,l,resizeactive,-10 0
    binde=,k,resizeactive,0 -10
    binde=,j,resizeactive,0 10
    binde=SHIFT,h,resizeactive,100 0
    binde=SHIFT,l,resizeactive,-100 0
    binde=SHIFT,k,resizeactive,0 -100
    binde=SHIFT,j,resizeactive,0 100
  ''
# Resize_ctl:1 ends here
