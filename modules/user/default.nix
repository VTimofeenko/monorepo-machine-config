# [[file:../../new_project.org::*NixOS user configs][NixOS user configs:1]]
{ pkgs
, config
, lib
, my-doom-config
, ...
}:
{
  users.users.spacecadet = {
    isNormalUser = true;
    extraGroups = [ "wheel" "lp" ];
    shell = pkgs.zsh;
  };

  # TODO: check if still needed
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.spacecadet = { ... }: {
    imports = [
      my-doom-config.nixosModules.default
      ../home-manager
    ];
    home.packages = builtins.attrValues {
      inherit (pkgs) ncspot pavucontrol blueman libreoffice firefox brave gthumb;
    };

    programs.browserpass.enable = true;

    programs.password-store = {
      enable = true;
      package = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
    };

    home.file.".icons/default".source = "${pkgs.vanilla-dmz}/share/icons/Vanilla-DMZ";
  };
}
# NixOS user configs:1 ends here
