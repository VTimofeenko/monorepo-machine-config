{
  description = "Sample check flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      checks.${system}.test = pkgs.testers.runNixOSTest {
        name = "test";
        node.specialArgs = {
          inherit (self) inputs outputs;
        };
        nodes.machine1 =
          _: # { config, pkgs, ... }:
          {
            services.getty.autologinUser = "alice";
            imports = [ inputs.home-manager.nixosModules.home-manager ];
            users.users.alice = {
              isNormalUser = true;
              password = "hunter2";
            };

            home-manager.extraSpecialArgs = {
              inherit (self) inputs outputs;
            };
            home-manager.users.alice =
              _: # { config, ... }: # config is home-manager's config, not the OS one
              {
                imports = [ ];
                home.stateVersion = "23.11";
              };
          };
        # If developing a proper test script, see
        # https://nixos.org/manual/nixos/stable/#ssec-machine-objects
        testScript = "start_all()";
      };
    };
}
