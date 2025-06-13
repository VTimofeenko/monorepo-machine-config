/**
  Flake module that provides a wrapper around `ipython` with some commonly used libraries.
*/
_: {
  perSystem =
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

      ipython = pkgs.writeShellApplication {
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
    in
    {
      apps = {
        ipython = {
          type = "app";
          program = ipython;
        };
      };
      packages = { inherit ipython; };
    };
}
