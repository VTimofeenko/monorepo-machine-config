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
    # FIXME: Restore this service when I start running `mongodb` on a host that
    # supports AVX. Think about using `mongodb-ce` to avoid compilation.
    enable = false;
    enableLocalDB = true;

    settings.SPOTIFY_PUBLIC =
      lib.homelab.getServiceConfig serviceName |> builtins.getAttr "spotifyPublic";
    spotifySecretFile = config.age.secrets."${serviceName}-spotify-secret".path;
  };

}
