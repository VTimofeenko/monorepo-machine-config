# [[file:new_project.org::*Flake intro][Flake intro:1]]
{
  description = "NixOS configuration by Vladimir Timofeenko";
  # Flake intro:1 ends here
  # [[file:new_project.org::*Inputs][Inputs:1]]
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.05";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager.url = "github:rycee/home-manager/release-23.05";
    agenix.url = "github:ryantm/agenix";

    # Theming and stuff
    base16 = {
      url = "github:SenchoPens/base16.nix";
    };

    color_scheme = {
      url = "github:ajlende/base16-atlas-scheme";
      flake = false;
    };
    private-config = {
      url = "git+file:///home/spacecadet/code/private-flake?ref=master";
      # url = "git+ssh://gitea@gitea.srv.vtimofeenko.com/spacecadet/private-flake.git";
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
      url = "git+file:///home/spacecadet/code/doom-config";
      # url = "git+ssh://gitea@gitea.srv.vtimofeenko.com/spacecadet/doom-config.git";
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

    # Service that remaps arbitrary keyboard combinations
    xremap-flake.url = "github:xremap/nix-flake?ref=20-home-manager-module";

    devshell.url = "github:numtide/devshell";

    pyprland.url = "github:VTimofeenko/pyprland?ref=nix";

    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    naersk.url = "github:nix-community/naersk/master";
  };
  # Inputs:1 ends here
  # [[file:new_project.org::*Outputs intro][Outputs intro:1]]
  outputs =
    inputs@{ flake-parts
    , private-config
    , self
    , ...
    }:
    flake-parts.lib.mkFlake
      { inherit inputs; }
      (
        { withSystem, flake-parts-lib, ... }:
        {
          # Outputs intro:1 ends here
          # [[file:new_project.org::*Imports][Imports:1]]
          imports = [
            inputs.devshell.flakeModule
            inputs.flake-parts.flakeModules.easyOverlay
          ];
          # Imports:1 ends here
          # [[file:new_project.org::*Systems setting][Systems setting:1]]
          systems = [ "x86_64-linux" "aarch64-darwin" ];
          # Systems setting:1 ends here
          # [[file:new_project.org::*"perSystem" output]["perSystem" output:1]]
          perSystem = { config, self', inputs', pkgs, system, ... }:
            let
              pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
            in
            {
              # Per-system attributes can be defined here. The self' and inputs'
              # module parameters provide easy access to attributes of the same
              # system.
              # "perSystem" output:1 ends here
              # [[file:new_project.org::*Formatter][Formatter:1]]
              formatter = pkgs.nixpkgs-fmt; # (ref:formatter)
              # Formatter:1 ends here
              # [[file:new_project.org::*Packages][Packages:1]]
              packages =
                let
                  naersk-lib = pkgs-unstable.callPackage inputs.naersk { };
                in
                {
                  hyprland-lang-notifier = naersk-lib.buildPackage ./packages/hyprland-lang-notifier;
                  hyprland-mode-notifier = naersk-lib.buildPackage ./packages/hyprland-mode-notifier;
                  hyprland-switch-lang-on-xremap = naersk-lib.buildPackage ./packages/hyprland-switch-lang-on-xremap;
                };
              # Packages:1 ends here
              # [[file:new_project.org::*Overlays][Overlays:1]]
              overlayAttrs = {
                inherit (config.packages) hyprland-lang-notifier;
              };
              # Overlays:1 ends here
              # [[file:new_project.org::*homeConfigurations][homeConfigurations:1]]
              legacyPackages.homeConfigurations =
                let
                  /* Create the default homeManagerConfiguration with inherited pkgs.

                  The provided attrset will be merged into the homeManagerConfiguration.

                   Type: mkHmc :: attrset -> home-manger.lib.homeManagerConfiguration

                  */
                  mkHmc = attrset: inputs.home-manager.lib.homeManagerConfiguration ({ inherit pkgs; } // attrset);
                in
                {
                  # homeConfigurations:1 ends here
                  # [[file:new_project.org::*Deck][Deck:1]]
                  deck = mkHmc {
                    modules = [
                      ./modules/home-manager # (ref:deck-hm-import)
                      ./modules/home-manager/_perUser/deck.nix
                      inputs.xremap-flake.homeManagerModules.default # Enables xmreap without any features
                      ./modules/de/xremap/shortcuts.nix # Reuses xremap bindings from mainconfigs
                    ];
                  };
                  # Deck:1 ends here
                  # [[file:new_project.org::*Vtimofeenko][Vtimofeenko:1]]
                  vtimofeenko = mkHmc {
                    modules = [
                      ./modules/home-manager/home.nix
                      ./modules/home-manager/vim
                      ./modules/home-manager/git.nix
                      ./modules/home-manager/_perUser/vtimofeenko.nix
                    ];
                  };
                  # Vtimofeenko:1 ends here
                  # [[file:new_project.org::*homeConfigurations outro][homeConfigurations outro:1]]
                };
              # homeConfigurations outro:1 ends here
              # [[file:new_project.org::*devShells][devShells:1]]
              devshells.default = {
                env = [
                  {
                    name = "RUST_SRC_PATH";
                    value = pkgs-unstable.rustPlatform.rustLibSrc;
                  }
                ];
                commands = [
                  {
                    help = "preview README.md";
                    name = "preview";
                    command = "${pkgs.python310Packages.grip}/bin/grip .";
                  }
                  {
                    help = "deploy neptunium";
                    name = "deploy-neptunium";
                    command = "nixos-rebuild --flake .#neptunium --target-host root@neptunium.home.arpa switch";
                  }
                  {
                    help = "deploy uranium";
                    name = "deploy-uranium";
                    command = "nixos-rebuild --flake .#uranium --target-host root@uranium.home.arpa switch";
                  }
                  {
                    help = "deploy local machine";
                    name = "deploy-local";
                    command =
                      ''
                        if [[ $(grep -s ^NAME= /etc/os-release | sed 's/^.*=//') == "NixOS" ]]; then
                          sudo nixos-rebuild switch --flake .
                        else
                         home-manager switch --flake .
                        fi
                      '';
                  }
                ];
                packages = builtins.attrValues {
                  inherit (pkgs-unstable) cargo rustc rustfmt pre-commit gcc pkg-config;
                  inherit (pkgs-unstable.rustPackages) clippy;
                };

              };
              # devShells:1 ends here
              # [[file:new_project.org::*perSystem outro][perSystem outro:1]]
            };
          # perSystem outro:1 ends here
          # [[file:new_project.org::*"Flake" section]["Flake" section:1]]
          flake = {
            # The usual flake attributes can be defined here, including system-
            # agnostic ones like nixosModule and system-enumerating ones, although
            # those are more easily expressed in perSystem.
            # "Flake" section:1 ends here
            # [[file:new_project.org::*"nixosModules" output]["nixosModules" output:1]]
            nixosModules =
              let
                inherit (flake-parts-lib) importApply;
              in
              rec {
                default = { ... }: {
                  imports = [
                    zsh
                    nix-config
                  ];
                };
                zsh = import ./nixosModules/zsh; # (ref:zsh-module-import)
                nix-config = import ./nixosModules/nix; # (ref:nix-module-import)

                # Home manager modules follow
                hyprland-language-switch-notifier = importApply ./nixosModules/hyprland-language-switch-notifier { localFlake = self; inherit withSystem; }; # (ref:lang-switch-import)
                hyprland-mode-switch-notifier = importApply ./nixosModules/hyprland-mode-switch-notifier { localFlake = self; inherit withSystem; }; # (ref:mode-switch-import)
              };
            # "nixosModules" output:1 ends here
            # [[file:new_project.org::*"nixosConfigurations" output]["nixosConfigurations" output:1]]
            nixosConfigurations =
              let
                specialArgs = inputs // { selfModules = self.nixosModules; selfPkgs = self.packages; };
              in
              {
                # "nixosConfigurations" output:1 ends here
                # [[file:new_project.org::*Uranium][Uranium:1]]
                uranium = inputs.nixpkgs.lib.nixosSystem {
                  system = "x86_64-linux";
                  modules = [
                    ./modules
                    ./modules/nixosSystems/uranium # (ref:uranium-import)
                    private-config.nixosModules.machines.uranium
                    { nixpkgs.overlays = [ inputs.my-sway-config.overlays.default ]; }
                  ];
                  inherit specialArgs;
                };
                # Uranium:1 ends here
                # [[file:new_project.org::*Neptunium][Neptunium:1]]
                neptunium = inputs.nixpkgs.lib.nixosSystem {
                  system = "x86_64-linux";
                  modules = [
                    ./modules
                    ./modules/nixosSystems/neptunium
                    private-config.nixosModules.machines.neptunium
                    # { nixpkgs.overlays = [ my-sway-config.overlays.default ]; }
                  ];
                  inherit specialArgs;
                };
                # Neptunium:1 ends here
                # [[file:new_project.org::*"nixosConfigurations" outro]["nixosConfigurations" outro:1]]
              };
            # "nixosConfigurations" outro:1 ends here
            # [[file:new_project.org::*"Flake" output outro]["Flake" output outro:1]]
          };
          # "Flake" output outro:1 ends here
          # [[file:new_project.org::*Flake outro][Flake outro:1]]
        }
      );
}
# Flake outro:1 ends here
