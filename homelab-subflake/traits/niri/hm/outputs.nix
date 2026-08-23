{ osConfig, ... }:
let
  # Per-host `output` blocks. niri auto-detects/arranges monitors
  # reasonably well on its own (see carbon), so only list a host here if
  # it actually needs an override.
  perHost = {
    uranium = ''
      output "eDP-1" {
          mode "2256x1504@60"
          position x=0 y=0
          scale 1
      }
    '';
    # TODO: neptunium has different monitors -- fill in once known.
  };
in
{
  # Included from config.kdl. Empty for hosts with no entry above, which is
  # a valid (no-op) niri config file.
  xdg.configFile."niri/outputs.kdl".text = perHost.${osConfig.networking.hostName} or "";
}
