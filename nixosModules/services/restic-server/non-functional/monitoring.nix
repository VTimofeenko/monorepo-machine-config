{
  services.restic.server.prometheus = true;
  services.restic.server.extraFlags = [ "--prometheus-no-auth" ];
  # TODO: allow firewall access from prometheus host?
}
