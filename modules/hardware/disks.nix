# [[file:../../new_project.org::*Disks][Disks:1]]
_: {
  # Disks:1 ends here
  # [[file:../../new_project.org::*Disks][Disks:2]]
  services.fstrim.enable = true;
  # Disks:2 ends here
  # [[file:../../new_project.org::*Disks][Disks:3]]
  systemd.tmpfiles.rules = [ "d /scratch 1777 spacecadet users 10d" ];
  # Disks:3 ends here
  # [[file:../../new_project.org::*Disks][Disks:4]]
}
# Disks:4 ends here
