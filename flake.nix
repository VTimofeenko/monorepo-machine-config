{
  description = "NixOS and Home Manager configurations for my machines";
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

    # Theming and stuff
    base16 = {
      url = "github:SenchoPens/base16.nix";
    };

    color_scheme = {
      url = "github:ajlende/base16-atlas-scheme";
      flake = false;
    };

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
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

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
      # url = "path:///home/spacecadet/code/data-flake";
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
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nitrocli = {
      url = "github:d-e-s-o/nitrocli?dir=contrib/nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    docspell-flake = {
      url = "github:eikek/docspell?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

  };
  outputs =
    inputs@{ flake-parts
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
          /* Import the public flake modules.

          The attribute names don't matter */
          publicFlakeModules = {
            nvimModule = importApply ./flake-modules/vim { inherit withSystem self; };
            tmuxModule = importApply ./flake-modules/tmux { inherit withSystem self; };
            zshModule = importApply ./flake-modules/zsh { inherit self; };
            gitModule = importApply ./flake-modules/git;
            hyprlandHelpersModule = importApply ./flake-modules/hyprland-helpers { inherit withSystem lib self; };
            emacsModule = importApply ./flake-modules/emacs {
              inherit withSystem lib self importApply;
              inherit (inputs) kroki-src;
            };
            themeModule = importApply ./flake-modules/theme { inherit lib self; };
          };
        in
        {
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
          systems = [ "x86_64-linux" "aarch64-darwin" "aarch64-linux" ];
          perSystem = { config, inputs', pkgs, ... }: {
            overlayAttrs = config.packages;
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
                deck = mkHmc {
                  modules = [
                    ./modules/home-manager
                    ./modules/home-manager/_perUser/deck.nix
                    inputs.xremap-flake.homeManagerModules.default
                    ./modules/de/xremap/shortcuts.nix
                  ];
                };
              };
            bumpInputs = {
              changingInputs = [ "private-config" "my-flake-modules" "hostsBlockList" "data-flake" ];
              bumpAllInputs = true;
            };
            # My modules config
            format-module = {
              languages = [ "lua" "shell" "rust" ];
              addFormattersToDevshell = true;
            };
            devshellCmds.deployment = {
              enable = true;
              localDeployment = true;
              useDeployRs = true;
            };

            devshells.default = let devShellCmds = import ./lib/devshellCmds.nix { inherit pkgs; }; in {
              env = [ ];
              commands = devShellCmds;
              packages = [ ];
            };

            packages = {
              hostsBlockList = import ./packages/hostsBlockList { inherit pkgs; src = inputs.hostsBlockList; };
              /* Nitrocli pinned to more current nixpkgs to save on rebuilding.
                   Needed occasionally so not part of the world. */
              nitrocli = inputs'.nitrocli.packages.default;
              /* Package with some services icons */
              dashboard-icons = import ./packages/dashboard-icons/package.nix { inherit (pkgs) stdenv fetchFromGitHub; };
              /* Desktop icons */
              arcticons = import ./packages/arcticons/package.nix { inherit (pkgs) stdenv fetchFromGitHub inkscape scour xmlstarlet yq jq; };

            };
          };
          flake =
            let
              homelab = import ./lib/homelab.nix {
                inherit (inputs) nixpkgs self deploy-rs;
                inherit (inputs.nixpkgs) lib;
              };
            in
            {
              /* flake-modules are passed through to the output of this flake */
              inherit (inputs.my-flake-modules) flake-modules;
              nixosModules =
                let nix-config = import ./nixosModules/nix; in
                {
                  default = { ... }: {
                    imports = [
                      self.nixosModules.zsh
                      nix-config
                    ];
                  };
                  inherit nix-config;
                };
              nixosConfigurations =
                let
                  specialArgs = inputs // { selfModules = self.nixosModules; selfPkgs = self.packages; selfHMModules = self.homeManagerModules; };
                in
                  /* Iterates over the attrset of managed nodes, creating the nixosConfigurations per machine */
                (builtins.mapAttrs
                  (_: hostData: homelab.mkSystem { inherit hostData specialArgs; inherit (inputs) data-flake; })
                  inputs.data-flake.data.hosts.managed)
                //
                {
                  neutronium-x86_64 =
                    inputs.nixpkgs.lib.nixosSystem {
                      system = "x86_64-linux";
                      modules = [
                        "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
                        inputs.data-flake.nixosModules.data
                        ./nixosConfigurations/neutronium
                      ];
                    };
                  uranium = inputs.nixpkgs.lib.nixosSystem {
                    system = "x86_64-linux";
                    modules = [
                      inputs.nur.nixosModules.nur
                      ./modules
                      ./modules/nixosSystems/uranium # (ref:uranium-import)
                      # private-config.nixosModules.machines.uranium
                      inputs.data-flake.nixosModules.uranium
                    ];
                    inherit specialArgs;
                  };
                  # FIXME: not implemented

                  # neptunium = inputs.nixpkgs.lib.nixosSystem {
                  #   system = "x86_64-linux";
                  #   modules = [
                  #     inputs.nur.nixosModules.nur
                  #     ./modules
                  #     ./modules/nixosSystems/neptunium
                  #   ];
                  #   inherit specialArgs;
                  # };
                  nitrogen-seed = inputs.nixpkgs.lib.nixosSystem {
                    system = "x86_64-linux";
                    modules = [
                      inputs.data-flake.nixosModules.data
                      inputs.disko.nixosModules.disko
                      ./nixosConfigurations/nitrogen/seed
                    ];
                    inherit specialArgs;
                  };
                };
              deploy.nodes =
                lib.recursiveUpdate
                  (builtins.mapAttrs
                    (hostName: hostData: homelab.mkDeployRsNode
                      {
                        nodeName = hostData.hostName;
                        inherit (hostData) system;
                      })
                    inputs.data-flake.data.hosts.managed)
                  {
                    /* Temporary overrides can be configured here like so:

                    hydrogen.hostname = "192.168.1.1";
                    */
                  }
              ;
              overlays.homelab = _: prev: withSystem prev.stdenv.hostPlatform.system ({ config, ... }: {
                inherit (config.packages) hostsBlockList dashboard-icons;
              });

              homeManagerModules = {
                kitty = import ./modules/homeManager/kitty;
              };

              templates.default = {
                path = ./templates/base;
                description = "Base template for my projects";
              };
            };
        }
      );
}
