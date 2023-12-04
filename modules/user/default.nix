# [[file:../../new_project.org::*NixOS user configs][NixOS user configs:1]]
{ pkgs
  # , my-doom-config
, nixpkgs-unstable
, selfHMModules
, ...
}:
{
  users.users.spacecadet = {
    isNormalUser = true;
    extraGroups = [ "wheel" "lp" ];
    shell = pkgs.zsh;
  };
  home-manager = {

    # TODO: check if still needed
    useGlobalPkgs = true;
    useUserPackages = true;

    extraSpecialArgs = {
      inherit nixpkgs-unstable;
    };
    users.spacecadet = { ... }:
      {
        imports = [
          # my-doom-config.nixosModules.default
          ../home-manager # (ref:linux-user-import)
          selfHMModules.vim
          {
            programs.myNvim = { enable = true; withLangServers = true; };
          }
          selfHMModules.zsh
          selfHMModules.git
          selfHMModules.emacs
        ];
        home.packages = builtins.attrValues {
          inherit (pkgs) pavucontrol blueman libreoffice brave gthumb;
        };

        programs.browserpass.enable = true;

        programs.password-store = {
          enable = true;
          package = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
        };

        home.file.".icons/default".source = "${pkgs.vanilla-dmz}/share/icons/Vanilla-DMZ";
      };
  };
}
# NixOS user configs:1 ends here
