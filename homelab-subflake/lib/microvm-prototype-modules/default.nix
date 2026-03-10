/**
  Nix files in this directory are functions of a microVM name. They generate
  NixOS modules for the guest and the host.
*/
microVMName:
{
  imports =
    [
      ./host
      ./guest
    ]
    |> map (it: (import it) microVMName);
}
