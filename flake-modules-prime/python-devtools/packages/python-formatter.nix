{
  writeShellApplication,
  ruff,
  black,
  callPackage,
}:
let
  ruffConfig = callPackage ./common/ruff-config.nix { };
in
writeShellApplication {
  name = "python-formatter";

  runtimeInputs = [
    ruff
    black
  ];

  text = ''
    black --line-length 120 "$@" |
      ruff check\
          --config ${ruffConfig} \
          --fix \
          --preview \
          --quiet \
          --exit-zero `# it can keep complaining to stderr, but should not fail. EFM uses zero exit code to apply the change` \
  '';
}
