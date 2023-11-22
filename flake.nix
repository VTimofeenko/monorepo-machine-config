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
    snowcli.url = "github:sfc-gh-vtimofeenko/snowcli?ref=nix-flake&dir=contrib/nix";

    nixpkgs-lib.url = "github:NixOS/nixpkgs/nixos-unstable?dir=lib";

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
    xremap-flake.url = "github:xremap/nix-flake";

    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs-unstable";

    pyprland.url = "github:VTimofeenko/pyprland?ref=nix";

    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    pre-commit-hooks-nix = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.nixpkgs-stable.follows = "nixpkgs";

    };
    # vim plugins
    vim-scratch-plugin = {
      url = "github:mtth/scratch.vim";
      flake = false;
    };
    nvim-devdocs = {
      url = "github:luckasRanarison/nvim-devdocs";
      flake = false;
    };

    # My development stuff
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs-lib";
    };
    my-flake-modules = {
      url = "github:VTimofeenko/flake-modules";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        nixpkgs-unstable.follows = "nixpkgs-unstable";
        nixpkgs-stable.follows = "nixpkgs";
        nixpkgs-lib.follows = "nixpkgs-lib";
        flake-parts.follows = "flake-parts";
        pre-commit-hooks-nix.follows = "pre-commit-hooks-nix";
        devshell.follows = "devshell";
      };
    };
    # Rust
    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.rust-analyzer-src.follows = "";
    };

    advisory-db = {
      url = "github:rustsec/advisory-db";
      flake = false;
    };
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
        let
          inherit (inputs.nixpkgs-lib) lib;# A faster way to propagate lib to certain modules
          inherit (flake-parts-lib) importApply;
          publicFlakeModules = {
            nvimModule = importApply ./flake-modules/vim { inherit withSystem self; };
            zshModule = importApply ./flake-modules/zsh { inherit self; };
            gitModule = importApply ./flake-modules/git;
            hyprlandHelpersModule = importApply ./flake-modules/hyprland-helpers { inherit withSystem lib self; };
          };
        in
        {
          # Outputs intro:1 ends here
          # [[file:new_project.org::*Imports][Imports:1]]
          imports =
            (builtins.concatLists [
              [
                inputs.devshell.flakeModule
                inputs.flake-parts.flakeModules.easyOverlay
                inputs.pre-commit-hooks-nix.flakeModule
              ]
              # Construct imports from this flake's flake modules
              (lib.lists.flatten (map builtins.attrValues [ inputs.my-flake-modules.flake-modules publicFlakeModules ]))
            ]);
          # Imports:1 ends here
          # [[file:new_project.org::*Systems setting][Systems setting:1]]
          systems = [ "x86_64-linux" "aarch64-darwin" "aarch64-linux" ];
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
              # [[file:new_project.org::*Overlays][Overlays:1]]
              overlayAttrs = builtins.attrValues config.packages;
              # Overlays:1 ends here
              # [[file:new_project.org::*homeConfigurations][homeConfigurations:1]]
              legacyPackages.homeConfigurations =
                let
                  /* Create the default homeManagerConfiguration with inherited pkgs.

                  The provided attrset will be merged into the homeManagerConfiguration.

                   Type: mkHmc :: attrset -> home-manger.lib.homeManagerConfiguration

                  */
                  mkHmc = attrset: inputs.home-manager.lib.homeManagerConfiguration ({
                    inherit pkgs;
                    extraSpecialArgs = { inherit inputs' inputs; selfModules = self.nixosModule; selfPkgs = self.packages; };
                  } // attrset);
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
                  # [[file:new_project.org::*homeConfigurations outro][homeConfigurations outro:1]]
                };
              # homeConfigurations outro:1 ends here
              changingInputs = [ "private-config" ];
              # [[file:new_project.org::*devShells][devShells:1]]

              devshells.default = {
                env = [ ];
                commands = [ ];
                packages = builtins.attrValues {
                  inherit (pkgs-unstable) pre-commit gcc pkg-config;
                };

              };
              # devShells:1 ends here
              # [[file:new_project.org::*perSystem outro][perSystem outro:1]]
            };
          # perSystem outro:1 ends here
          # [[file:new_project.org::*"Flake" section]["Flake" section:1]]
          flake =
            let
              inherit (flake-parts-lib) importApply;
            in
            {
              # Pass this through
              inherit (inputs.my-flake-modules) flake-modules;
              # The usual flake attributes can be defined here, including system-
              # agnostic ones like nixosModule and system-enumerating ones, although
              # those are more easily expressed in perSystem.
              # "Flake" section:1 ends here
              # [[file:new_project.org::*"nixosModules" output]["nixosModules" output:1]]
              nixosModules =
                rec {
                  default = { ... }: {
                    imports = [
                      self.nixosModules.zsh
                      nix-config
                    ];
                  };
                  tmux = importApply ./nixosModules/tmux { localFlake = self; inherit inputs; }; # (ref:tmux-module-import)
                  nix-config = import ./nixosModules/nix; # (ref:nix-module-import)
                };
              # "nixosModules" output:1 ends here
              # [[file:new_project.org::*"nixosConfigurations" output]["nixosConfigurations" output:1]]
              nixosConfigurations =
                let
                  specialArgs = inputs // { selfModules = self.nixosModules; selfPkgs = self.packages; selfHMModules = self.homeManagerModules; };
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
                    ];
                    inherit specialArgs;
                  };
                  # Neptunium:1 ends here
                  # [[file:new_project.org::*"nixosConfigurations" outro]["nixosConfigurations" outro:1]]
                };
              # "nixosConfigurations" outro:1 ends here
              # [[file:new_project.org::*"homeManagerModules" output]["homeManagerModules" output:1]]
              # "homeManagerModules" output:1 ends here
              # [[file:new_project.org::*"Flake" output outro]["Flake" output outro:1]]
            };
          # "Flake" output outro:1 ends here
          # [[file:new_project.org::*Flake outro][Flake outro:1]]
        }
      );
}
# Flake outro:1 ends here
