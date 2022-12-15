{
  description = "NixOS configuration by Vladimir Timofeenko";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.11";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager.url = "github:rycee/home-manager/release-22.11";
    agenix.url = "github:ryantm/agenix";

    # Theming and stuff
    base16 = {
      url = "github:SenchoPens/base16.nix";
      # One input only
      inputs.nixpkgs.follows = "nixpkgs";
    };

    color_scheme = {
      url = "github:ajlende/base16-atlas-scheme";
      flake = false;
    };
    private-config = {
      url = "git+ssh://gitea@gitea.srv.vtimofeenko.com/spacecadet/private-flake.git";
      inputs = {
        agenix.follows = "agenix";
        nixpkgs.follows = "nixpkgs";
      };
    };
    my-zsh = {
      url = "github:VTimofeenko/zsh-flake";
      # One input only
      inputs.nixpkgs.follows = "nixpkgs";
    };
    my-tmux = {
      url = "github:VTimofeenko/tmux-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        base16.follows = "base16";
        color_scheme.follows = "color_scheme";
      };
    };

    my-nvim-flake.url = "path:/home/spacecadet/code/nvim-flake";

    my-sway-config = {
      url = "git+file:///home/spacecadet/code/sway-flake?ref=master";
      inputs = {
        base16.follows = "base16";
        color-scheme.follows = "color_scheme";
      };
    };
    # nur.url = "github:nix-community/NUR";
    my-doom-config = {
      url = "path:/home/spacecadet/code/doom-config";
    };
    wg-namespace-flake = {
      url = "path:///home/spacecadet/code/wg-namespace-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    infra = {
      url = "git+ssh://gitea@gitea.srv.vtimofeenko.com/spacecadet/infra-hosts.git";
      flake = false;
    };
  };

  outputs =
    inputs@{ nixpkgs
    , nixos-hardware
    , home-manager
    , agenix
    , my-zsh
    , my-nvim-flake
    , private-config
    , my-sway-config
    , ...
    }:

    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
        overlays = [
          # nur.overlay
          (final: prev: {
            my_nvim = my-nvim-flake.defaultPackage."${system}";
          })
          my-sway-config.overlays.default
        ];
      };
      commonModulesFromInputs = [
        # Enable secrets management
        agenix.nixosModule
        home-manager.nixosModules.home-manager
        inputs.my-tmux.nixosModule
        my-zsh.nixosModules.default
        {
          my_zsh.starship_enable = true;
          my_zsh.direnv_enable = true;
          my_zsh.gpg_enable = true;
        }
        {
          home-manager.users.spacecadet = my-sway-config.nixosModules.default;
        }
        {
          home-manager.users.spacecadet = { ... }: {
            wayland.windowManager.sway.config = {
              # Restore non-vm modifier
              modifier = "Mod4";
              # Output configuration
              output = {
                "eDP-1" = { "scale" = "1"; };
              };
            };
            vt-sway.enableBrightness = true;
          };
        }
        my-sway-config.nixosModules.system
        {
          # Needed, otherwise error
          # error: cannot look up '<nixpkgs>' in pure evaluation mode
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.spacecadet.home.stateVersion = "22.05";
        }
        # My emacs module
        {
          home-manager.users.spacecadet = inputs.my-doom-config.nixosModules.default;
        }
        inputs.wg-namespace-flake.nixosModules.default
        private-config.nixosModules.commonNodeModule
      ];

      commonCustomModules = [
        ./modules/applications
        ./modules/common
        ./modules/development
        ./modules/development/cross-compile.nix
        ./modules/development/virtualization.nix
        ./modules/hardware/dygma.nix

        # Network
        ./modules/network/common_lan.nix
        ./modules/network/lan-wifi.nix
      ];
      # Function to keep everything similar
      mkMyModules = list: list ++ commonModulesFromInputs ++ commonCustomModules;
    in

    {
      nixosConfigurations = {

        uranium = nixpkgs.lib.nixosSystem {
          inherit pkgs system;
          modules = mkMyModules [
            ./hosts/uranium
            private-config.nixosModules.management-network-control-node
            private-config.nixosModules.wg-namespace-config
          ];
          # NOTE:
          # This makes the inputs propagate into the modules and allows modules to refer to the inputs
          # See network configuration as an example
          specialArgs = inputs;
        };
      };

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;

    };
}
