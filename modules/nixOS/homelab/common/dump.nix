# Miscellaneous config setting dump
_: {
  /*
    Keeps the logs only in RAM

    TODO: move this to proper log collection module when that's ready
  */
  services.journald.extraConfig = ''
    Storage=volatile
    RuntimeMaxUse=50M
  '';
}
