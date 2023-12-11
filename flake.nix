# [[file:new_project.org::*Flake intro][Flake intro:1]]
{
  description = "NixOS configuration by Vladimir Timofeenko";
  # Flake intro:1 ends here
  # [[file:new_project.org::*Inputs][Inputs:1]]
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager.url = "github:rycee/home-manager/release-23.11";
    nixpkgs-lib.url = "github:NixOS/nixpkgs/nixos-unstable?dir=lib";
    nur.url = "github:nix-community/NUR";
    nixpkgs-stable.url = "nixpkgs";

    deploy-rs.url = "github:serokell/deploy-rs";
    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        darwin.follows = "stub-flake";
      };
    };

    infra = {
      url = "git+ssh://gitea@gitea.srv.vtimofeenko.com/spacecadet/infra-hosts.git";
      flake = false;
    };

    # Theming and stuff
    base16 = {
      url = "github:SenchoPens/base16.nix";
    };

    color_scheme = {
      url = "github:ajlende/base16-atlas-scheme";
      flake = false;
    };
    private-config = {
      # url = "git+file:///home/spacecadet/code/private-flake?ref=master";
      url = "git+ssh://gitea@gitea.srv.vtimofeenko.com/spacecadet/private-flake.git";
      inputs = {
        agenix.follows = "agenix";
        nixpkgs.follows = "nixpkgs";
      };
    };

    # my-doom-config = {
    #   url = "github:VTimofeenko/doom-config";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    hyprland.url = "github:hyprwm/Hyprland";

    # Service that remaps arbitrary keyboard combinations
    xremap-flake.url = "github:xremap/nix-flake";

    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs-unstable";
    pyprland = {
      url = "github:VTimofeenko/pyprland?ref=nix";
      inputs = {
        devshell.follows = "devshell";
        flake-parts.follows = "flake-parts";
      };
    };

    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    pre-commit-hooks-nix = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        nixpkgs-stable.follows = "nixpkgs";
      };
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
    # TODO: move to upstream url once pull/133 is merged
    treefmt-nix.url = "github:VTimofeenko/treefmt-nix?ref=nickel-syntax-fix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs-unstable";

    my-flake-modules = {
      url = "github:VTimofeenko/flake-modules";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        nixpkgs-unstable.follows = "nixpkgs-unstable";
        nixpkgs-stable.follows = "nixpkgs-stable";
        nixpkgs-lib.follows = "nixpkgs-lib";
        flake-parts.follows = "flake-parts";
        pre-commit-hooks-nix.follows = "pre-commit-hooks-nix";
        devshell.follows = "devshell";
        treefmt-nix.follows = "treefmt-nix";
        deploy-rs.follows = "deploy-rs";
      };
    };
    # Rust
    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Unused at the moment. TODO: use this with the local packages
    # fenix = {
    #   url = "github:nix-community/fenix";
    #   inputs.nixpkgs.follows = "nixpkgs-unstable";
    #   inputs.rust-analyzer-src.follows = "";
    # };

    # advisory-db = {
    #   url = "github:rustsec/advisory-db";
    #   flake = false;
    # };

    data-flake = {
      url = "git+ssh://gitea@gitea.srv.vtimofeenko.com/spacecadet/data-flake.git";
      inputs = {
        devshell.follows = "devshell";
        nixpkgs-lib.follows = "nixpkgs-lib";
        nixpkgs-stable.follows = "nixpkgs-stable";
        pre-commit-hooks-nix.follows = "pre-commit-hooks-nix";
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs-unstable";
        agenix.follows = "agenix";
        my-flake-modules.follows = "my-flake-modules";
        treefmt-nix.follows = "treefmt-nix";
        stub-flake.follows = "stub-flake";
      };
    };
    # Source for DNS block
    hostsBlockList = {
      flake = false;
      url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
    };
    # Empty flake
    stub-flake.url = "github:VTimofeenko/stub-flake"; # A completely empty flake
    # Source for org-excalidraw converter for emacs
    kroki-src = {
      url = "github:yuzutech/kroki-cli";
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
            emacsModule = importApply ./flake-modules/emacs {
              inherit withSystem lib self importApply;
              inherit (inputs) kroki-src;
            };
          };
        in
        {
          # Outputs intro:1 ends here
          # [[file:new_project.org::*Imports][Imports:1]]
          imports =
            builtins.concatLists [
              [
                inputs.devshell.flakeModule
                inputs.flake-parts.flakeModules.easyOverlay
                inputs.pre-commit-hooks-nix.flakeModule
                inputs.treefmt-nix.flakeModule
              ]
              # Construct imports from this flake's flake modules
              (lib.lists.flatten (map builtins.attrValues [ inputs.my-flake-modules.flake-modules publicFlakeModules ]))
            ];
          # Imports:1 ends here
          # [[file:new_project.org::*Systems setting][Systems setting:1]]
          systems = [ "x86_64-linux" "aarch64-darwin" "aarch64-linux" ];
          # Systems setting:1 ends here
          # [[file:new_project.org::*"perSystem" output]["perSystem" output:1]]
          perSystem = { config, inputs', pkgs, system, ... }:
            let
              pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
            in
            {
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
              bumpInputs = {
                changingInputs = [ "private-config" "my-flake-modules" "hostsBlockList" "data-flake" ];
                bumpAllInputs = true;
              };
              # [[file:new_project.org::*devShells][devShells:1]]

              # My modules config
              format-module = {
                languages = [ "lua" "shell" "rust" ];
                addFormattersToDevshell = true;
              };
              devshellCmds.deployment = {
                enable = true;
                localDeployment = true;
              };

              devshells.default = {
                env = [ ];
                commands = [ ];
                packages = builtins.attrValues {
                  inherit (pkgs-unstable) gcc pkg-config;
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
                  tmux = importApply ./nixosModules/tmux { inherit inputs; }; # (ref:tmux-module-import)
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
                      inputs.nur.nixosModules.nur
                      ./modules
                      ./modules/nixosSystems/uranium # (ref:uranium-import)
                      private-config.nixosModules.machines.uranium
                      inputs.data-flake.nixosModules.uranium
                    ];
                    inherit specialArgs;
                  };
                  # Uranium:1 ends here
                  # [[file:new_project.org::*Neptunium][Neptunium:1]]
                  neptunium = inputs.nixpkgs.lib.nixosSystem {
                    system = "x86_64-linux";
                    modules = [
                      inputs.nur.nixosModules.nur
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
