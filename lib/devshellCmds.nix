/* Devshell commands to check various things */
{ pkgs, ... }:
[
  {
    help = "Check the DNS replies";
    name = "check-dns";
    command =
      let
        checkScript = pkgs.writeShellApplication {
          name = "check-dns";
          runtimeInputs = builtins.attrValues { inherit (pkgs) dig; };
          text = /* bash */''
            set -euo pipefail

            test_list=( hydrogen.home.arpa google.com gitea.srv.vtimofeenko.com helium.mgmt.home.arpa doubleclick.net roku.com )
            dns_servers=( helium.home.arpa hydrogen.home.arpa )

            for dns in "''${dns_servers[@]}"; do
              echo "Checking $dns"
              for i in "''${test_list[@]}"; do

              echo "$i"
              dig +short "$i" @"$dns"

              done
            done
          '';
        };
      in
      pkgs.lib.getExe checkScript;
  }
  {
    help = "Deploy dashboard";
    name = "deploy-dashboard";
    # TODO: depend on emacs, scp and config somehow
    command = "emacsclient -eval '(org-batch-store-agenda-views)' && scp ~-infra/services/dashy/home_maint.html root@nitrogen.mgmt.home.arpa:/var/lib/filedump";
  }
]
