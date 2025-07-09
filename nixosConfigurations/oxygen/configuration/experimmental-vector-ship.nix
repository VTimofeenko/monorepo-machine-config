/**
  Quick implementation of the new log shipper.

  Experimental phase will last while I figure out the data model and filtering rules.
*/
{ lib, ... }:
{
  services.vector = {
    enable = true;

    settings = {
      sources.local-journald.type = "journald";

      sinks.log-concentrator = {
        type = "vector";
        inputs = [ "local-journald" ];
        address = "log-concentrator" |> lib.homelab.services.getInnerIP |> (it: "${it}:6000");
      };
    };

    journaldAccess = true;
  };
}
