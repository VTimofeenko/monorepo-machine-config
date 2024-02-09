# [[file:../../../new_project.org::*Power_ctl][Power_ctl:1]]
mkModeBinding: _:
mkModeBinding "SUPERCTRL,P" "Power" ''
  # Exit hyprland
  bind=, Q, exit
  # Suspend
  bind=, S, exec, systemctl suspend
  # Shutdown
  bind=SHIFT, S, exec, systemctl shutdown
  # Reboot
  bind=SHIFT, R, exec, systemctl reboot
''
# Power_ctl:1 ends here
