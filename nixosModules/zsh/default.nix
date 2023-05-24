# [[file:../../new_project.org::*zsh (system)][zsh (system):2]]
{ pkgs, config, lib, ... }:
let
  # This kinda imports the user module and exposes the parameters through userConfig attrset
  userConfig = import ../../modules/home-manager/zsh { inherit pkgs config lib; };
in
{
  environment.systemPackages = userConfig.home.packages;
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    # Enabled inside the hm module
    enableCompletion = false;
    inherit (userConfig.programs.zsh) shellAliases;
    interactiveShellInit = userConfig.programs.zsh.initExtra;
    promptInit =
      builtins.concatStringsSep
        "\n"
        (
          map
            (x:
              ''
                if [[ $TERM != "dumb" && (-z $INSIDE_EMACS || $INSIDE_EMACS == "vterm") ]]; then
                  ${x}
                fi
              ''
            )
            [
              # Enable starship prompt
              ''eval "$(${pkgs.starship}/bin/starship init zsh)"''
              # Direnv setup
              ''eval "$(${pkgs.direnv}/bin/direnv hook zsh)"''
              # Any nix shell setup
              ''${pkgs.any-nix-shell}/bin/any-nix-shell zsh --info-right | source /dev/stdin''
            ]
        );
  };
  # System-level completions need this
  environment.pathsToLink = [ "/share/zsh" ];
}
# zsh (system):2 ends here
