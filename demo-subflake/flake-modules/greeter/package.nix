{
  writeShellApplication,
  lib,
  ...
}:
writeShellApplication {
  name = "greeter";
  text = ''echo "Hello from the flake-module-loader Pattern B!"'';
  meta.description = "Demo package produced by Pattern B convention";
}
