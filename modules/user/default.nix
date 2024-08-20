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

    # TODO: check if still needed
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

        programs.browserpass.enable = true;

        programs.password-store = {
          enable = true;
          package = pkgs.pass.withExtensions (exts: [
            exts.pass-otp
            exts.pass-genphrase
          ]);
        };

        home.file.".icons/default".source = "${pkgs.vanilla-dmz}/share/icons/Vanilla-DMZ";
      };
  };
}
# NixOS user configs:1 ends here
