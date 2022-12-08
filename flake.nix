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
    vt-zsh = {
      url = "github:VTimofeenko/zsh-flake";
      # One input only
      inputs.nixpkgs.follows = "nixpkgs";
    };
    my_tmux = {
      url = "github:VTimofeenko/tmux-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        base16.follows = "base16";
        color_scheme.follows = "color_scheme";
      };
    };

    vt-colors.url = "path:/home/spacecadet/Documents/projects/vt-colors";
    vt-nvim-flake.url = "path:/home/spacecadet/code/nvim-flake";

    lynis-flake = {
      url = "path:/home/spacecadet/Documents/projects/lynis-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vt-sway = {
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
  };

  outputs =
    inputs@{ nixpkgs
    , nixos-hardware
    , home-manager
    , agenix
    , vt-colors
    , vt-zsh
    , vt-nvim-flake
    , private-config
    , lynis-flake
    , vt-sway
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
            my_nvim = vt-nvim-flake.defaultPackage."${system}";
          })
          vt-sway.overlays.default
        ];
      };
      commonModulesFromInputs = [
        # Enable secrets management
        agenix.nixosModule
        home-manager.nixosModules.home-manager
        # TODO: check if needed
        vt-colors.nixosModule
        {
          my_colors.enable = true;
        }
        inputs.my_tmux.nixosModule
        vt-zsh.nixosModule
        {
          my_zsh.starship_enable = true;
          my_zsh.direnv_enable = true;
          my_zsh.gpg_enable = true;
        }
        {
          home-manager.users.spacecadet = vt-sway.nixosModules.default;
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
        vt-sway.nixosModules.system
        {
          # Needed, otherwise error
          # error: cannot look up '<nixpkgs>' in pure evaluation mode
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        }
        # My emacs module
        {
          home-manager.users.spacecadet = inputs.my-doom-config.nixosModules.default;
        }
        inputs.wg-namespace-flake.nixosModules.default
      ];

      commonCustomModules = [
        ./modules/hardware/dygma.nix
        ./modules/applications
        ./modules/development
        ./modules/development/cross-compile.nix
        ./modules/development/virtualization.nix

        # Network
        ./modules/network/common_lan.nix
        ./modules/network/lan-wifi.nix
      ] ++ (with private-config.nixosModules; [
        sudo
        smartcard
        user-ssh-config
        syncthing
      ]);
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
        };
      };

    };
}
