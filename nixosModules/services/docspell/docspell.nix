{
  config,
  pkgs,
  docspell-flake,
  ...
}:
let
  inherit (config) my-data;
  srvName = "docspell";
  srv = my-data.lib.getService srvName;
  serviceConfig = my-data.lib.getServiceConfig srvName;
  full-text-search = {
    enabled = true;
    backend = "postgresql";
    postgresql.use-default-connection = true;
  };

  docspell-packages = docspell-flake.packages.${pkgs.system};
in
{
  services = {
    docspell-joex = {
      enable = true;

      base-url = "https://${srv.fqdn}";

      package = docspell-packages.docspell-joex;

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

      base-url = "https://${srv.fqdn}";

      package = docspell-packages.docspell-restserver;

      bind = {
        address = "localhost";
        port = 7880;
      };
      inherit (serviceConfig) auth admin-endpoint openid;

      inherit full-text-search;
      backend = {
        signup.mode = "closed";
        inherit (serviceConfig) jdbc;
      };

      extraConfig.auth.on-account-source-conflict = "convert";

      # extraConfig.files.stores.filesystem =
      #   {
      #     enabled = true;
      #     type = "file-system";
      #     directory = minioCloneDir;
      #   };
    };
  };
}
