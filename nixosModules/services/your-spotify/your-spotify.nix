{
  config,
  lib,
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
}
