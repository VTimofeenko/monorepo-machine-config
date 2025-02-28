{
  pkgs,
  lib,
  docspell-flake,
  config,
  ...
}:
let
  inherit (lib.homelab) getService getServiceConfig;
  srvName = "docspell";

  srv = getService srvName;
  serviceConfig = getServiceConfig srvName;

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

      # Joex likes to sleep on the job. Let's wake it up more often.
      scheduler.wakeup-period = "1 minute";

      inherit (serviceConfig) jdbc;
      inherit full-text-search;

      convert.wkhtmlpdf = {
        working-dir = "/tmp/docspell-convert/";
        command = {
          program = lib.mkForce "${pkgs.python3Packages.weasyprint}/bin/weasyprint";
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

      internal-url = "http://${config.services.docspell-restserver.bind.address}:${config.services.docspell-restserver.bind.port |> toString}";

      package = docspell-packages.docspell-restserver;

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

  imports = lib.localLib.mkImportsFromDir ./functional;
}
