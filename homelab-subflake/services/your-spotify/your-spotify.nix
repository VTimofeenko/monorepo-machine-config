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
    # FIXME: age.secrets."your-spotify-spotify-secret" is referenced here but
    #        not declared in this file — verify it is declared in a private module,
    #        or add: age.secrets."your-spotify-spotify-secret".file = lib.homelab.getSrvSecret serviceName "spotify-secret";
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
