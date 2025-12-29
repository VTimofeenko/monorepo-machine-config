{
  config,
  lib,
  pkgs,
  ...
}:
let
  serviceName = "your-spotify";
in
{
  services.your_spotify = {
    enable = true;
    enableLocalDB = true;

    settings.SPOTIFY_PUBLIC =
      lib.homelab.getServiceConfig serviceName |> builtins.getAttr "spotifyPublic";
    spotifySecretFile = config.age.secrets."${serviceName}-spotify-secret".path;
  };

  services.mongodb = {
    enable = true;
    package = pkgs.mongodb-ce;
    dbpath = "/var/lib/mongodb";
    extraConfig = ''
      storage:
        wiredTiger:
          engineConfig:
            cacheSizeGB: 0.25
      operationProfiling:
        mode: off
    '';
  };

  environment.systemPackages = [ pkgs.mongodb-tools ];
}
