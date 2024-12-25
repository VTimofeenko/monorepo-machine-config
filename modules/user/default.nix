# [[file:../../new_project.org::*NixOS user configs][NixOS user configs:1]]
{
  pkgs,
  nixpkgs-unstable,
  selfHMModules,
  data-flake,
  catppuccin,
  ...
}:
{
  users.users.spacecadet = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "lp"
    ];
    shell = pkgs.zsh;
  };
  home-manager = {

    useGlobalPkgs = true;
    useUserPackages = true;

    extraSpecialArgs = {
      inherit nixpkgs-unstable;
    };
    users.spacecadet =
      { ... }:
      {
        imports = [
          ../home-manager # (ref:linux-user-import)

          catppuccin.homeManagerModules.catppuccin

          selfHMModules.vim
          {
            programs.myNeovim = {
              enable = true;
              withLangServers = true;
            };
          }

          selfHMModules.zsh
          selfHMModules.git
          selfHMModules.emacs
          selfHMModules.my-theme
          data-flake.homeManagerModules.default
        ];
        home.packages = builtins.attrValues {
          inherit (pkgs)
            pavucontrol
            blueman
            libreoffice
            brave
            gthumb
            ;
        };

        home.file.".icons/default".source = "${pkgs.vanilla-dmz}/share/icons/Vanilla-DMZ";

        programs = {

          browserpass.enable = true;

          password-store = {
            enable = true;
            package = pkgs.pass.withExtensions (exts: [
              exts.pass-otp
              exts.pass-genphrase
            ]);
          };

          # Overrides for broot
          broot = {
            settings.preview_transformers = [
              {
                input_extensions = [ "pdf" ];
                output_extension = "png";
                mode = "image";
                command = [
                  "${pkgs.mupdf-headless}/bin/mutool"
                  "draw"
                  "-w"
                  "1000"
                  "-o"
                  "{output-path}"
                  "{input-path}"
                  "1"
                ];
              }
            ];
          };
        };
      };
  };
}
# NixOS user configs:1 ends here
