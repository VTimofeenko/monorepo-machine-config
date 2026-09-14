{ pkgs, ... }:
{
  programs.niri.enable = true;
  systemd.user.services.niri = {
    enableDefaultPath = false; # From NixOS wiki

    # A package/version bump to `niri` changes this unit's closure, so a plain
    # `deploy-$node` would otherwise restart the *running* `niri.service` mid-
    # session, killing the compositor.
    # Leave the running instance alone; the new build is still activated and
    # takes effect on the next manual restart/re-login.
    restartIfChanged = false;

    # niri's own teardown (forcing graphical-session.target to stop via
    # niri-shutdown.target) normally happens in the `niri-session` wrapper
    # script, *after* `niri.service` exits -- but that script skips its
    # teardown and execs straight into `niri --session` when it detects it's
    # already being run as a systemd --user unit (see the `$MANAGERPID`/
    # `$SYSTEMD_EXEC_PID` check at the top of niri's `resources/niri-session`),
    # which is the case for greetd. Without it, quitting niri (Mod+Shift+E)
    # leaves graphical-session.target -- and anything bound to it, e.g.
    # NIRI_SOCKET-dependent services -- stuck running with stale state until
    # a full reboot. Attach the same teardown directly to niri.service so it
    # runs regardless of how the session was launched.
    #
    # `--no-block` is required: ExecStopPost runs *inside* niri.service's own
    # stop transaction, and the queued job to tear down graphical-session.target
    # loops back to niri.service (still mid-stop) -- waiting on it here (the
    # default, blocking behavior) deadlocks the whole thing.
    serviceConfig.ExecStopPost = "${pkgs.systemd}/bin/systemctl --user start --no-block --job-mode=replace-irreversibly niri-shutdown.target";
  };
}
