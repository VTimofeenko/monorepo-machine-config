/**
  Home manager module for centerpiece launcher config.

  https://github.com/friedow/centerpiece

  This module is a simple wrapper that takes nix config expression and writes
  out the yaml expected by centerpiece
*/
{
  pkgs,
  config,
  lib,
  ...
}:
let
  settingsFormat = pkgs.formats.yaml { };
  cfg = config.programs.centerpiece;
in
{
  options.programs.centerpiece = {
    enable = lib.mkEnableOption "centerpiece";

    package = lib.mkPackageOption pkgs "centerpiece" { };

    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = settingsFormat.type;
      };
      default = { };
      description = ''
        Configuration for centerpiece, see
        https://github.com/friedow/centerpiece?tab=readme-ov-file#configure
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      let
        # This wrapper prevents multiple centerpiece instances from starting
        centerpiece-locking-wrapper = pkgs.writeShellApplication {
          name = cfg.package.meta.mainProgram;

          runtimeInputs = [
            cfg.package
            pkgs.util-linux # flock here
          ];

          # Source:
          # https://stackoverflow.com/posts/1985512/revisions
          text = # bash
            ''
              LOCKFILE="$XDG_RUNTIME_DIR/centerpiece.lock"
              LOCKFD=99

              _lock()             { flock -"$1" $LOCKFD; }
              _no_more_locking()  { _lock u; _lock xn && rm -f "$LOCKFILE"; }
              _prepare_locking()  { eval "exec $LOCKFD>\"$LOCKFILE\""; trap _no_more_locking EXIT; }


              # ON START
              _prepare_locking

              # PUBLIC
              exlock_now()        { _lock xn; }  # obtain an exclusive lock immediately or fail
              exlock()            { _lock x; }   # obtain an exclusive lock
              shlock()            { _lock s; }   # obtain a shared lock
              unlock()            { _lock u; }   # drop a lock

              ### BEGIN OF SCRIPT ###

              # Simplest example is avoiding running multiple instances of script.
              exlock_now || exit 1

              centerpiece "$@"
            '';
        };
      in
      [ centerpiece-locking-wrapper ];

    xdg.configFile."centerpiece/config.yml".source = settingsFormat.generate "config" cfg.settings;
  };
}
