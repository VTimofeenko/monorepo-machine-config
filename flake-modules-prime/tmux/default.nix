# Flake module that produces NixOS module and application to run tmux with my config
{ self, ... }:
let
  # builder needs { self }
  tmuxConfBuilder = import ./builder.nix { inherit self; };
in
{
  perSystem =
    { pkgs, ... }:
    let
      inherit
        (tmuxConfBuilder {
          inherit (pkgs) lib;
          inherit pkgs;
        })
        tmuxConf
        ;

      tmuxConfFile = pkgs.writeText "tmux.conf" tmuxConf;

      tmuxWrapper = pkgs.writeShellApplication {
        name = "tmux-wrapper";
        runtimeInputs = [ pkgs.tmux ];
        text = "tmux -f ${tmuxConfFile}";
      };
    in
    {
      apps.tmux = {
        type = "app";
        program = pkgs.lib.getExe tmuxWrapper;
      };
    };
  flake = {
    nixosModules.tmux = import ./module.nix { inherit tmuxConfBuilder; };
  };
}
