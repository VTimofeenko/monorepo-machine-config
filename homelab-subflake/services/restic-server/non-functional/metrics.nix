{
  services.restic.server = {
    prometheus = true;
    extraFlags = [ "--prometheus-no-auth" ];
  };
}
