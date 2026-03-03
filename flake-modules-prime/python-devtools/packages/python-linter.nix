{
  writeShellApplication,
  ruff,
  callPackage
}:
let
  ruffConfig = callPackage ./common/ruff-config.nix { };
in
writeShellApplication {
  name = "python-linter";

  runtimeInputs = [ ruff ];

  text = ''
    ruff check\
          --config ${ruffConfig} \
          --quiet \
          --preview \
          "$@"
  '';
}
