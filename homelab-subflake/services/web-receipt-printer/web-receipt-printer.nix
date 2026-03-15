{ self, ... }:
let
  manifest = self.lib.getManifest "web-receipt-printer";
in
{
  imports = [ ./impl.nix ];
  services.web-receipt-printer = {
    enable = true;
    port = manifest.endpoints.web.port;
  };
}
