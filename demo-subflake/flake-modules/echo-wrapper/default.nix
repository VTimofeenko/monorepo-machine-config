{ self, withSystem, lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.echo-wrapper = pkgs.writeShellApplication {
        name = "echo-wrapper";
        text = ''echo "Hello from the flake-module-loader Pattern A!" "$@"'';
      };
      apps.echo-wrapper = {
        type = "app";
        program = self.packages.${pkgs.system}.echo-wrapper;
      };
    };
}
