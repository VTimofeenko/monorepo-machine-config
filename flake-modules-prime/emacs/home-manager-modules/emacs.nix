# Home-manager module that configures Doom emacs
{ pkgs, lib, ... }:
let
  emacs-with-flags = pkgs.emacs30.override {
    withNativeCompilation = true;
    withSQLite3 = true;
    withTreeSitter = true;
    withWebP = true;
  };

  # Looks like desktopEntry/tmpfiles want these absolute
  doomRepoLocation = "/home/spacecadet/.local/share/doom-emacs";
  doomDir = "/home/spacecadet/.config/doom";
  gitManageddoomDir = "/home/spacecadet/code/literate-machine-config/flake-modules-prime/emacs/doom.dir";
in
{
  programs = {
    emacs = {
      enable = true;
      package = emacs-with-flags;
      extraPackages =
        epkgs:
        [
          epkgs.vterm
          # For :spell
          (pkgs.aspellWithDicts (
            ds: with ds; [
              en
              en-computers
              en-science
              ru
            ]
          ))
        ]
        ++
          /*
            External dependencies.

            NOTE: According to https://github.com/NixOS/nixpkgs/issues/267548 this sometimes breaks
          */
          builtins.attrValues {
            inherit (pkgs)
              fd # fast find
              ripgrep # fast grep
              sqlite # org roam
              lua-language-server # lua LSP
              graphviz # dot for roam
              beancount-language-server
              kroki-cli
              bash-language-server
              ;
          };
    };
    zsh = {
      shellAliases = {
        # Add "doom" alias
        doom = "${doomRepoLocation}/bin/doom";
        # Override "emacs" alias with proper init dir
        emacs = "emacs --init-directory ${doomRepoLocation}";
      };
    };
  };

  # Exported (not just zsh-local) so any subprocess doom/emacs spawns -- and
  # bare `doom sync`/`doom doctor` runs from any shell -- resolve to the same
  # non-default locations instead of silently falling back to
  # ~/.config/emacs et al.
  home.sessionVariables = {
    DOOMDIR = doomDir;
    EMACSDIR = doomRepoLocation;
    # Pin explicitly: straight's build tree is versioned by Emacs version
    # (build-<version>/), so if this were left to a bare PATH lookup, any
    # stray/other Emacs ahead of it on PATH would silently build packages
    # against the wrong version.
    EMACS = lib.getExe emacs-with-flags;
  };

  xdg.desktopEntries = {
    emacs = {
      name = "Emacs";
      # Explicit env instead of relying on session-var propagation: launcher
      # invocations don't go through zsh/home.sessionVariables, so DOOMDIR
      # can silently resolve to the wrong default here otherwise.
      exec = "env DOOMDIR=${doomDir} EMACSDIR=${doomRepoLocation} emacs --init-directory ${doomRepoLocation} %F";
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

  # NOTE: doom-emacs itself is *not* bootstrapped by home-manager activation
  # anymore (that was fragile: silent failures, and a no-op once the
  # directory exists once, so it could never self-heal). Bootstrap it
  # manually after first switch:
  #
  #   git clone --depth=1 --single-branch https://github.com/doomemacs/doomemacs ${doomRepoLocation}
  #   ${doomRepoLocation}/bin/doom install -!
  #
  # NOTE: it must be `install`, not `sync`, on a fresh ${doomRepoLocation}.
  # `sync` assumes `install` already ran once; skipping straight to `sync`
  # silently resolves stock doom modules (evil, doom-themes, etc.) as
  # `&nopath` (see `doom info`) and only ever builds what packages.el
  # declares directly, which quietly looks "done" while being half-loaded.
  # DOOMDIR/EMACSDIR/EMACS are already exported via home.sessionVariables
  # above, so no extra flags are needed here.

  # Doom really wants its dir in .config. I want to manage everything in this repo.
  # xdg.configFile."doom".source = config.lib.file.mkOutOfStoreSymlink gitManageddoomDir;
  systemd.user.tmpfiles.rules = [ "L ${doomDir} - - - - ${gitManageddoomDir} " ];
}
