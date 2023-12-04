# Home-manager module that configures Doom emacs
{ pkgs
, lib
, ...
}:
let
  /* */
  emacs-with-flags = pkgs.emacs29.override {
    withNativeCompilation = true;
    withSQLite3 = true;
    withTreeSitter = true;
    withWebP = true;
  };

  doomGit = "https://github.com/doomemacs/doomemacs";
  doomRepoLocation = "$XDG_CACHE_HOME/hm-doom-repo";
  # Looks like tmpfiles wants this to be absolute
  # doomDir = "$XDG_CONFIG_HOME/doom";
  # gitManageddoomDir = "$HOME/code/literate-machine-config/modules/emacs/doom.dir";
  doomDir = "/home/spacecadet/.config/doom";
  gitManageddoomDir = "/home/spacecadet/code/literate-machine-config/modules/emacs/doom.dir";
in
{
  programs = {
    emacs = {
      enable = true;
      package = emacs-with-flags;
      # extraPackages = epkgs: [ epkgs.magit ];
    };
    zsh = {
      # Add "doom" alias
      shellAliases.doom = "${doomRepoLocation}/bin/doom";
      # This allows keeping the doom config in place
      localVariables.DOOMDIR = doomDir;
    };
  };

  # TODO: add all icons font?
  # TODO: patch the desktop

  /* This activation script will check out doom-emacs into a pre-defined directory

    It should check if the directory exist and become a no-op if it does ('true' part)
  */
  home.activation.gitCheckoutDoom = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD [ ! -d ${doomRepoLocation} ] && ${lib.getExe pkgs.git} clone --depth=1 --single-branch "${doomGit}" "${doomRepoLocation} || true"
  '';

  # Doom really wants its dir in .config. I want to manage everything in this repo.
  # xdg.configFile."doom".source = config.lib.file.mkOutOfStoreSymlink gitManageddoomDir;
  systemd.user.tmpfiles.rules = [
    "L ${doomDir} - - - - ${gitManageddoomDir} "
  ];
}
