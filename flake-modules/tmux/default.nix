# Flake module that produces NixOS module and application to run tmux with my config
{ withSystem, self }:
let
  tmuxConfBuilder = import ./builder.nix { inherit (self) inputs; };
in
{
  perSystem =
    { system, ... }:
    {
      apps = withSystem system (
        { inputs', ... }:
        let
          pkgs = inputs'.nixpkgs.legacyPackages;
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
          tmux = {
            type = "app";
            program = tmuxWrapper;
          };
        }
      );
    };
  flake = {
    nixosModules.tmux = import ./module.nix { inherit tmuxConfBuilder; };
  };
}
