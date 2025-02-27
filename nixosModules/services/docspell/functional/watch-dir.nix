/**
  Files can be uploaded to `$fqdn/watch-dir`. They will be periodically picked up by `dsc` utility.

  This module implements the actual file manager service.

  TODO:
  1. [X] set up _a_ watch-dir
  2. [X] Add to SSL proxy
  3. [X] Make sure the files start existing when uploaded
  4. Add periodic `dsc`? Check docker file. It will need to use the same state directory
  5. Add to dashboard
*/
{
  pkgs,
  lib,
  ...
}:
{
  systemd.services.docspell-watch-dir = {
    after = [ "network-online.target" ];
    requires = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      User = "docspell";
      Group = "docspell";
      StateDirectory = "docspell-watch-dir";
      ExecStart =
        [
          "${pkgs.gossa |> lib.getExe}"
          "-h ${lib.homelab.getOwnIpInNetwork "backbone-inner"}"
          "-p 8002"
          "-prefix '/watch-dir/'"
          # location
          "$STATE_DIRECTORY"
        ]
        |> builtins.concatStringsSep " ";
    };
  };
}
