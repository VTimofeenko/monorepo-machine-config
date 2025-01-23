/**
  Global aliases substitute part of the command when it's interpreted.

  Given:
  ```
  alias -g G="| rg"
  ```
  Command `ls G foo` will show only results that match "foo"
*/
{ lib, ... }:
let
  settings.globalAliases = {
    # `G` to grep
    G = "| rg";
    # `C` to `ccopy`; alias to copy into clipboard
    C = "| ccopy";
    # `V` to view in vim
    V = "| vim -R";
  };
  init =
    settings.globalAliases
    # Escape everything
    |> lib.mapAttrs' (
      name: value: lib.nameValuePair (name |> lib.escapeShellArg) (value |> lib.escapeShellArg)
    )
    # Create the alias lines
    |> lib.mapAttrsToList (name: value: "alias -g ${name}=${value}")
    # Join it all.
    #
    # Implementation note: Alternative is to use `concatMapAttrsStringSep` but it's a bit less clear when reading it
    |> lib.concatStringsSep "\n";
in
{
  nixosModule = {
    programs.zsh.interactiveShellInit = init;
  };
  homeManagerModule = {
    programs.zsh.initExtra = init;
  };
}
