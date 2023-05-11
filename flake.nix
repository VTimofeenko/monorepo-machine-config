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
    my-tmux = {
      url = "github:VTimofeenko/tmux-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        base16.follows = "base16";
        color_scheme.follows = "color_scheme";
      };
    };

    my-nvim-flake.url = "github:VTimofeenko/nvim-flake";

    my-sway-config = {
      url = "git+file:///home/spacecadet/code/sway-flake?ref=master";
      inputs = {
        base16.follows = "base16";
        color-scheme.follows = "color_scheme";
      };
    };
    # nur.url = "github:nix-community/NUR";
    my-doom-config = {
      url = "git+ssh://gitea@gitea.srv.vtimofeenko.com/spacecadet/doom-config.git";
    };
    wg-namespace-flake = {
      url = "git+ssh://gitea@gitea.srv.vtimofeenko.com/spacecadet/wireguard-namespace-flake.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    infra = {
      url = "git+ssh://gitea@gitea.srv.vtimofeenko.com/spacecadet/infra-hosts.git";
      flake = false;
    };

    hyprland.url = "github:hyprwm/Hyprland";

  };

  outputs =
    inputs@{ flake-parts
    , nixos-hardware
    , home-manager
    , agenix
    , my-nvim-flake
    , private-config
    , my-sway-config
    , self
    , ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ ];
      systems = [ "x86_64-linux" "aarch64-darwin" ];

      perSystem = { config, self', inputs', pkgs, system, ... }:
        {
          formatter = pkgs.nixpkgs-fmt;

          legacyPackages.homeConfigurations =
            let
              hmc = attrset: home-manager.lib.homeManagerConfiguration ({ inherit pkgs; } // attrset); # shortcut
              _defaultModules =
                [
                  ./homeConfigurations/home.nix
                  ./homeConfigurations/vim
                  ./homeConfigurations/kitty
                  ./homeConfigurations/zsh
                ];
            in
            rec {
              deck = hmc
                {
                  modules =
                    _defaultModules
                    ++
                    [ ./homeConfigurations/_perUser/deck.nix ];
                };
              vtimofeenko = hmc
                {
                  modules =
                    [
                      ./homeConfigurations/home.nix
                      ./homeConfigurations/vim
                      ./homeConfigurations/_perUser/vtimofeenko.nix
                    ];
                };
              spacecadet = hmc
                {
                  modules =
                    [
                      ./homeConfigurations/home.nix
                      ./homeConfigurations/vim
                    ];
                };

              # homeConfigurations closing bracket
            };

          # perSystem closing bracket
        };

      flake = {

        nixosModules = rec {
          default = { ... }: {
            imports = [
              zsh
              nix-config
            ];
          };
          zsh = import ./modules/zsh;
          nix-config = import ./modules/common/nix-config.nix;
          swaySystemModule = import ./modules/sway/system;
        };

        nixosConfigurations =
          let
            _commonModulesFromInput =
              [
                agenix.nixosModules.default
                home-manager.nixosModules.home-manager
                inputs.my-tmux.nixosModule
                {
                  programs.vt-zsh =
                    {
                      starship_enable = true;
                      direnv_enable = true;
                      gpg_enable = true;
                      enableAnyNixShell = true;
                    };
                }
                { home-manager.users.spacecadet = my-sway-config.nixosModules.default; }
                my-sway-config.nixosModules.system
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
            _commonLocalModules =
              [
                ./modules/applications
                ./modules/common
                ./modules/development
                ./modules/development/cross-compile.nix
                ./modules/development/virtualization.nix
                ./modules/hardware/dygma.nix
                ./modules/hardware/disks.nix
                ./modules/hardware/printer.nix
                ./modules/hardware/scanner.nix
                ./modules/zsh

                # Network
                ./modules/network/common_lan.nix
                ./modules/network/lan-wifi.nix
              ];
            mkMyModules = list: list ++ _commonLocalModules ++ _commonModulesFromInput;
            _allUserModules =
              [
                ./homeConfigurations/vim
              ];
            # A set of modules to be imported for the user-specific configuration
            # TODO: move to homeConfigurations
            _homeModules =
              [
                inputs.my-doom-config.nixosModules.default
                inputs.hyprland.homeManagerModules.default

                # my hyprland config
                ./modules/hyprland
                # kitty config
                ./modules/applications/kitty.nix
              ] ++ _allUserModules;

            # pkgs = import nixpkgs {
            #   inherit system;
            #   config = { allowUnfree = true; };
            #   overlays = [
            #     # nur.overlay
            #     (final: prev: {
            #       my_nvim = my-nvim-flake.defaultPackage."${system}";
            #     })
            #     my-sway-config.overlays.default
            #   ];
            # };
          in
          {

            uranium = inputs.nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              modules = mkMyModules [
                ./hosts/uranium
                private-config.nixosModules.management-network-control-node
                private-config.nixosModules.wg-namespace-config
                ./modules/steam
                { nixpkgs.overlays = [ my-sway-config.overlays.default ]; }
              ];
              # NOTE:
              # This makes the inputs propagate into the modules and allows modules to refer to the inputs
              # See network configuration as an example
              specialArgs = inputs;
            };

            neptunium = inputs.nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              modules = [
                ./hosts/neptunium
                # private-config.nixosModules.management-network-control-node
                # private-config.nixosModules.wg-namespace-config
                # NOTE: not reuisng certain modules during sway setup
                ./modules/zsh
                ./modules/common
                ./modules/hardware/dygma.nix
                ./modules/network/common_lan.nix
                agenix.nixosModules.default
                home-manager.nixosModules.home-manager
                inputs.my-tmux.nixosModule
                inputs.hyprland.nixosModules.default
                ./modules/sway/system/greeter.nix
                ./modules/sway/system/hyprland.nix
                ./modules/development/editor.nix
                {
                  programs.vt-zsh = {
                    starship_enable = true;
                    direnv_enable = true;
                    gpg_enable = true;
                    enableAnyNixShell = true;
                  };
                }
                {
                  # Needed, otherwise error
                  # error: cannot look up '<nixpkgs>' in pure evaluation mode
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.users.spacecadet.home.stateVersion = "22.05";
                }
                {
                  home-manager.users.spacecadet = inputs.nixpkgs.lib.mkMerge _homeModules;
                }
              ];
              specialArgs = inputs;
            };

            # Closing bracket for nixosConfigurations
          };

      };
    };
}
