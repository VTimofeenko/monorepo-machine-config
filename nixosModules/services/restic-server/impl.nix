{
  services.restic.server = {
    enable = true;
    extraFlags = [
      "--no-auth"
    ];
  };
}
