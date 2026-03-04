let
  settings.homeCodeDirectory="code";
in
{
  # `nixosModule` does not configure this
  nixosModule = { };
  homeManagerModule =
    { config, ... }:
    {
      programs.direnv = {
        enable = true;
        config.warn_timeout = "15s";
        nix-direnv.enable = true;
        config.whitelist.prefix = [ "${config.home.homeDirectory}/${settings.homeCodeDirectory}" ];
      };
    };
}
