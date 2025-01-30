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

          fzfHistorySearch =
            builtins.readFile ./ipython-fzf.py
            |> (it: {
              text = it;
              name = "ipython-fzf-history";
            })
            |> pkgs.writeTextFile;
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
                  python-pkgs.pyfzf
                ]))
                pkgs.fzf
              ];
              text = ''ipython --TerminalInteractiveShell.editing_mode=vi -i "${fzfHistorySearch}" "$@"'';
            };
          };
        }
      );
    };
}
