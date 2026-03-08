{ lib, ... }:
{
  services.vector = {
    enable = true;

    settings = {
      sources.local-journald.type = "journald";

      sinks.log-concentrator = {
        type = "vector";
        inputs = [ "local-journald" ];
        # 6000 is not stable. I need to establish "endpoints" logic for the service manifests and update this
        address = "log-concentrator" |> lib.homelab.services.getInnerIP |> (it: "${it}:6000");
      };
    };

    journaldAccess = true;
  };
}
