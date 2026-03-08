{
  /** Keeps logs only in RAM */
  services.journald.extraConfig = ''
    Storage=volatile
    RuntimeMaxUse=50M
  '';
}
