{ config, pkgs, ... }:
let
  inherit (config) my-data;
  srvName = "docspell";
  serviceConfig = my-data.lib.getServiceConfig srvName;
  full-text-search = {
    enabled = true;
    backend = "postgresql";
    postgresql.use-default-connection = true;
  };
in
{
  services = {
    docspell-joex = {
      enable = true;
      base-url = "http://localhost:7878";
      bind = {
        address = "localhost";
        port = 7878;
      };

      scheduler.pool-size = 1;

      inherit (serviceConfig) jdbc;
      inherit full-text-search;

      convert.wkhtmlpdf = {
        working-dir = "/tmp/docspell-convert/";
        command = {
          program = "${pkgs.python310Packages.weasyprint}/bin/weasyprint";
          args = [
            "--optimize-size"
            "all"
            "--encoding"
            "{{encoding}}"
            "-"
            "{{outfile}}"
          ];
        };
      };

      # extraConfig.files.stores.filesystem =
      #   {
      #     enabled = true;
      #     type = "file-system";
      #     directory = minioCloneDir;
      #   };
    };
    docspell-restserver = {
      enable = true;
      base-url = "http://localhost:7880";
      bind = {
        address = "localhost";
        port = 7880;
      };
      inherit (serviceConfig) auth admin-endpoint;

      inherit full-text-search;
      backend = {
        signup.mode = "closed";
        inherit (serviceConfig) jdbc;
      };

      # extraConfig.files.stores.filesystem =
      #   {
      #     enabled = true;
      #     type = "file-system";
      #     directory = minioCloneDir;
      #   };
    };
  };
}
