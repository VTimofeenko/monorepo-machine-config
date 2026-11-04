/**
  `swayosd-client` that shows the OSD only on niri's focused output.

  - swayosd draws on every monitor unless `--monitor` is passed per call
*/
{
  writeShellApplication,
  niri,
  jq,
  swayosd,
}:
writeShellApplication {
  name = "swayosd-focused";
  runtimeInputs = [
    niri
    jq
    swayosd
  ];
  text = ''
    target=()
    monitor=$(niri msg --json focused-output | jq -r '.name // empty') || monitor=""
    if [ -n "$monitor" ]; then target=(--monitor "$monitor"); fi
    exec swayosd-client "''${target[@]}" "$@"
  '';
}
