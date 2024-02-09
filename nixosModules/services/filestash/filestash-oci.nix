{ config, ... }:
let
  inherit (config) my-data;
  srvName = "filestash";
  service = my-data.lib.getService srvName;

  filestashDir = "/var/lib/${srvName}";
in
{
  virtualisation.oci-containers = {
    # Better systemd orchestration
    backend = "podman";
    containers = {
      filestash = {
        # YOLO
        image = "machines/filestash:latest";
        ports = [ "127.0.0.1:8334:8334" ];
        volumes = [
          "${filestashDir}:/app/data/state"
          "/mnt:/data"
        ];
        environment = {
          APPLICATION_URL = service.fqdn;
        };
        cmd = [ ];
      };
    };
  };
  systemd.tmpfiles.rules = [ "d ${filestashDir} 0755 1000 1000" ];
}
