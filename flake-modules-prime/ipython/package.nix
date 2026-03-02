/**
  Wrapper around `ipython` with some commonly used libraries.
*/
{
  writeShellApplication,
  python3,
  writeTextFile,
  fzf,
  ...
}:
let
  fzfHistorySearch =
    builtins.readFile ./ipython-fzf.py
    |> (it: {
      text = it;
      name = "ipython-fzf-history";
    })
    |> writeTextFile;
in
writeShellApplication {
  name = "ipython-wrapper";
  runtimeInputs = [
    (python3.withPackages (python-pkgs: [
      python-pkgs.ipython
      python-pkgs.toolz
      python-pkgs.rich
      python-pkgs.pyfzf
    ]))
    fzf
  ];
  text = ''ipython --TerminalInteractiveShell.editing_mode=vi -i "${fzfHistorySearch}" "$@"'';
}
