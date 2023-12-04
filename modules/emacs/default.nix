# Home-manager module that configures Doom emacs
{ pkgs
, lib
, ...
}:
let
  # TODO: Add arch-agnostic notification package
  /* */
  emacs-with-flags = pkgs.emacs29.override {
    withNativeCompilation = true;
    withSQLite3 = true;
    withTreeSitter = true;
    withWebP = true;
  };

  doomGit = "https://github.com/doomemacs/doomemacs";
  # Looks like desktopEntry requires this to be absolute
  doomRepoLocation = "/home/spacecadet/.cache/hm-doom-repo";
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
      extraPackages = epkgs: [ epkgs.vterm ];
    };
    zsh = {
      # Add "doom" alias
      shellAliases.doom = "${doomRepoLocation}/bin/doom";
      # This allows keeping the doom config in place
      localVariables.DOOMDIR = doomDir;
    };
  };

  xdg.desktopEntries = {
    emacs = {
      name = "Emacs";
      exec = "emacs --init-directory ${doomRepoLocation} %F";
      icon = "emacs";
      mimeType = [
        "text/english"
        "text/plain"
        "text/x-makefile"
        "text/x-c++hdr"
        "text/x-c++src"
        "text/x-chdr"
        "text/x-csrc"
        "text/x-java"
        "text/x-moc"
        "text/x-pascal"
        "text/x-tcl"
        "text/x-tex"
        "application/x-shellscript"
        "text/x-c"
        "text/x-c++"
        ""
      ];
      settings.StartupWMClass = "Emacs";
    };
  };

  # TODO: add all icons font?

  /* This activation script will check out doom-emacs into a pre-defined directory

    It should check if the directory exist and become a no-op if it does ('true' part)
  */
  # TODO: only if Linux
  home.activation.gitCheckoutDoom = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD [ ! -d ${doomRepoLocation} ] && ${lib.getExe pkgs.git} clone --depth=1 --single-branch "${doomGit}" "${doomRepoLocation} || true"
  '';

  # Doom really wants its dir in .config. I want to manage everything in this repo.
  # xdg.configFile."doom".source = config.lib.file.mkOutOfStoreSymlink gitManageddoomDir;
  # TODO: only if Linux?
  systemd.user.tmpfiles.rules = [
    "L ${doomDir} - - - - ${gitManageddoomDir} "
  ];
}