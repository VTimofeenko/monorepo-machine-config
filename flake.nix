{
  description = "NixOS and Home Manager configurations for my machines";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.11";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager.url = "github:rycee/home-manager/release-24.11";
    nixpkgs-lib.url = "github:NixOS/nixpkgs/nixos-unstable?dir=lib";

    nur = {
      url = "github:nix-community/NUR";
      inputs.flake-parts.follows = "flake-parts";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };

    nixpkgs-stable.follows = "nixpkgs";

    deploy-rs.url = "github:serokell/deploy-rs";
    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        darwin.follows = "stub-flake";
        home-manager.follows = "home-manager";
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

    # TODO: move to proper module in nixpkgs
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1&rev=bd526822deb9ed47c0b51b534817aa8541fff07b";

    nvim-nightly = {
      url = "github:nix-community/neovim-nightly-overlay?rev=e87be8db9b99173d375a9ba3b4fd3a57aaa7386e";
    };

    # Service that remaps arbitrary keyboard combinations
    xremap-flake = {
      url = "github:xremap/nix-flake";
      inputs = {
        treefmt-nix.follows = "treefmt-nix";
        devshell.follows = "devshell";
        hyprland.follows = "stub-flake";
        home-manager.follows = "stub-flake";
      };
    };

    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs-unstable";

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
    # Disable for now, need to find alternative
    # nvim-devdocs = {
    #   url = "github:luckasRanarison/nvim-devdocs";
    #   flake = false;
    # };

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
    crane.url = "github:ipetkov/crane";

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
      url = "git+ssh://gitea@gitea.srv.vtimofeenko.com/spacecadet/data-flake.git"; # REMOTE_SRC
      # url = "path:///home/spacecadet/code/data-flake"; # LOCAL_SRC
      inputs = {
        devshell.follows = "devshell";
        nixpkgs-lib.follows = "nixpkgs-lib";
        nixpkgs-stable.follows = "nixpkgs-stable";
        nixpkgs-unstable.follows = "nixpkgs-unstable";
        pre-commit-hooks-nix.follows = "pre-commit-hooks-nix";
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs-unstable";
        agenix.follows = "agenix";
        my-flake-modules.follows = "my-flake-modules";
        treefmt-nix.follows = "treefmt-nix";
        stub-flake.follows = "stub-flake";
        terranix.follows = "stub-flake";
        nixpkgs-terraform-providers-bin.follows = "stub-flake";
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

    # TODO: Locked to reduce rebuilds. re-lock this after next docspell release
    docspell-flake = {
      # url = "github:eikek/docspell?rev=559f6df495f2c300b40d394220ea441ac6a003ee";
      url = "path:///home/spacecadet/code/forks/docspell/";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    redpanda-flake = {
      url = "github:fornybar/redpanda.nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.pre-commit-hooks.follows = "pre-commit-hooks-nix";
    };

    catppuccin.url = "git+https://github.com/VTimofeenko/catppucin-nix?ref=keep-gtk";

    # FIXME: [24.11] drop this in favor of a direct package import through
    # fetchFromGitHub.
    # Reason: I want to minimize the amount of inputs in this
    # flake as this leads to cartesian explosion of inputs in consumers.
    # The whole sequence of imports (here, flake-module, git home-manager
    # module) needs to go.
    # Cannot be done today because this flake is still pinned to 24.05 and the package needs a fresher version
    conventional-commit-helper = {
      url = "github:VTimofeenko/conventional-commit-helper";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        crane.follows = "crane";
        flake-parts.follows = "flake-parts";
      };
    };
  };
  outputs =
    inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { withSystem, flake-parts-lib, ... }:
      let
        inherit (inputs.nixpkgs-lib) lib; # A faster way to propagate lib to certain modules
        inherit (flake-parts-lib) importApply;
        /*
          Import the public flake modules.

          The attribute names don't matter
        */
        publicFlakeModules = {
          tmuxModule = importApply ./flake-modules/tmux { inherit withSystem self; };
          nvimModule = importApply ./flake-modules/neovim { inherit withSystem self; };
          zshModule = importApply ./flake-modules/zsh { inherit self; };
          gitModule = importApply ./flake-modules/git { inherit (inputs) conventional-commit-helper; };
          hyprlandHelpersModule = importApply ./flake-modules/hyprland-helpers {
            inherit withSystem lib self;
          };
          emacsModule = importApply ./flake-modules/emacs {
            inherit
              withSystem
              lib
              self
              importApply
              ;
            inherit (inputs) kroki-src;
          };
          themeModule = importApply ./flake-modules/theme { inherit lib self; };
          desktopEnvironment = importApply ./flake-modules/desktopEnvironment { inherit withSystem self; };
          ipython = importApply ./flake-modules/ipython { inherit withSystem self; };
        };
      in
      {
        imports = builtins.concatLists [
          [
            inputs.devshell.flakeModule
            inputs.flake-parts.flakeModules.easyOverlay
            inputs.pre-commit-hooks-nix.flakeModule
            inputs.treefmt-nix.flakeModule
          ]
          # Construct imports from this flake's flake modules
          (lib.lists.flatten (
            map builtins.attrValues [
              inputs.my-flake-modules.flake-modules
              publicFlakeModules
            ]
          ))
        ];
        systems = [
          "x86_64-linux"
          "aarch64-darwin"
          "aarch64-linux"
        ];
        perSystem =
          {
            config,
            inputs',
            pkgs,
            ...
          }:
          {
            overlayAttrs = config.packages;
            legacyPackages.homeConfigurations =
              let
                /*
                  Create the default homeManagerConfiguration with inherited pkgs.

                  The provided attrset will be merged into the homeManagerConfiguration.

                   Type: mkHmc :: attrset -> home-manger.lib.homeManagerConfiguration
                */
                mkHmc =
                  attrset:
                  inputs.home-manager.lib.homeManagerConfiguration (
                    {
                      inherit pkgs;
                      extraSpecialArgs = {
                        inherit inputs' inputs;
                        selfModules = self.nixosModule;
                        selfPkgs = self.packages;
                      };
                    }
                    // attrset
                  );
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
              changingInputs = [
                "my-flake-modules"
                "hostsBlockList"
                "data-flake"
                "nvim-nightly"
                "nixpkgs"
                "nixpkgs-unstable"
              ];
              bumpAllInputs = true;
            };
            # My modules config
            format-module = {
              languages = [
                "lua"
                "shell"
                "rust"
                "nickel"
              ];
              addFormattersToDevshell = true;
            };
            devshellCmds.deployment = {
              enable = true;
              localDeployment = true;
              useDeployRs = true;
              desktopNotifications = true;
            };

            devshells.default =
              let
                devShellCmds = import ./lib/devshellCmds.nix {
                  inherit pkgs;
                  inherit (inputs) data-flake;
                };
              in
              {
                env = [ ];
                commands = devShellCmds;
                packages = [ pkgs.nixos-anywhere ];
              };

            packages = {
              hostsBlockList = import ./packages/hostsBlockList {
                inherit pkgs;
                src = inputs.hostsBlockList;
              };
              /*
                Nitrocli pinned to more current nixpkgs to save on rebuilding.
                  Needed occasionally so not part of the world.
              */
              nitrocli = inputs'.nitrocli.packages.default;
              # Package with some services icons
              dashboard-icons = import ./packages/dashboard-icons/package.nix {
                inherit (pkgs) stdenv fetchFromGitHub;
              };
              # Desktop icons
              arcticons = import ./packages/arcticons/package.nix {
                inherit (pkgs)
                  stdenv
                  fetchFromGitHub
                  inkscape
                  scour
                  xmlstarlet
                  yq
                  jq
                  ;
              };

              # Wiz CLI
              riz = import ./packages/riz/package.nix {
                inherit (pkgs) fetchFromGitHub rustPlatform;
              };

              # Prometheus frigate exporter
              prometheus-frigate-exporter = import ./packages/prometheus-frigate-exporter/package.nix {
                inherit (pkgs) lib python3 fetchFromGitHub;
              };
            };
            checks = import ./checks { inherit self pkgs lib; };

            pre-commit = import ./.dev/pre-commit.nix { inherit inputs' lib pkgs; };
          };
        flake =
          let
            homelab = import ./lib/homelab.nix {
              # NOTE: Overlays from inputs are passed here
              inherit (inputs) nixpkgs self deploy-rs;
              inherit (inputs.nixpkgs) lib;
            };
          in
          {
            # flake-modules are passed through to the output of this flake
            inherit (inputs.my-flake-modules) flake-modules;
            nixosModules =
              let
                nix-config = importApply ./nixosModules/nix {
                  inherit (inputs) nixpkgs-stable nixpkgs-unstable;
                  inherit inputs;
                };
              in
              {
                default =
                  { ... }:
                  {
                    imports = [
                      self.nixosModules.zsh
                      nix-config
                    ];
                  };
                inherit nix-config;
              };
            nixosConfigurations =
              let
                specialArgs = inputs // {
                  selfModules = self.nixosModules;
                  selfPkgs = self.packages;
                  selfHMModules = self.homeManagerModules;
                };
              in
              # Iterates over the attrset of managed nodes, creating the nixosConfigurations per machine
              (builtins.mapAttrs (
                _: hostData:
                homelab.mkSystem {
                  inherit hostData specialArgs;
                  inherit (inputs) data-flake nur;
                }
              ) inputs.data-flake.data.hosts.managed)

              // (
                # Create -seed configs for hosts provisioning
                # Provisioning happens by
                # nix run github:nix-community/nixos-anywhere -- --flake .#<hostName>-seed root@<IP>
                lib.pipe
                  [
                    "nitrogen"
                    "fluorine"
                    "helium"
                    "lanthanum"
                  ]
                  [
                    (map (hostName: {
                      name = "${hostName}-seed";
                      value = inputs.nixpkgs.lib.nixosSystem {
                        inherit (inputs.data-flake.data.hosts.managed.${hostName}) system;
                        modules = [
                          inputs.data-flake.nixosModules.data
                          inputs.disko.nixosModules.disko
                          ./nixosConfigurations/${hostName}/seed
                        ];
                      };
                    }))
                    builtins.listToAttrs
                  ]
              )
              // {
                neutronium-x86_64 = inputs.nixpkgs.lib.nixosSystem {
                  system = "x86_64-linux";
                  modules = [
                    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
                    inputs.data-flake.nixosModules.data
                    ./nixosConfigurations/neutronium
                  ];
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
              };
            deploy.nodes =
              lib.recursiveUpdate
                (builtins.mapAttrs (
                  hostName: hostData:
                  homelab.mkDeployRsNode {
                    nodeName = hostData.hostName;
                    inherit (inputs) data-flake;
                    inherit (hostData) system;
                  }
                ) inputs.data-flake.data.hosts.managed)
                {
                  /*
                    Temporary overrides can be configured here like so:

                    hydrogen.hostname = "192.168.1.1";
                  */
                };
            overlays.homelab =
              _: prev:
              withSystem prev.stdenv.hostPlatform.system (
                { config, ... }:
                {
                  inherit (config.packages) hostsBlockList dashboard-icons;
                }
              );

            homeManagerModules = {
              kitty = import ./modules/homeManager/kitty;
              ideavim = import ./modules/homeManager/ideavim;
              nix-config = importApply ./nixosModules/nix {
                inherit (inputs) nixpkgs-stable nixpkgs-unstable;
                inherit inputs;
                inHomeManager = true;
              };
            };

            templates = {
              default = {
                path = ./templates/base;
                description = "Base template for my projects";
              };
              sample-check = {
                path = ./templates/sample-check;
                description = "Template for a sample check with home-manager.";
              };
            };
          };
      }
    );
}
