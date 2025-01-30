/**
  Flake module that provides a wrapper around ipython with some commonly used libraries.
*/
{ withSystem, ... }:
{
  perSystem =
    { system, ... }:
    {
      apps = withSystem system (
        { inputs', ... }:
        let
          pkgs = inputs'.nixpkgs.legacyPackages;
        in
        {
          ipython = {
            type = "app";
            program = pkgs.writeShellApplication {
              name = "ipython-wrapper";
              runtimeInputs = [
                (pkgs.python3.withPackages (python-pkgs: [
                  python-pkgs.ipython
                  python-pkgs.toolz
                  python-pkgs.rich
                ]))
              ];
              text = ''ipython --TerminalInteractiveShell.editing_mode=vi "$@"'';
            };
          };
        }
      );
    };
}
