{ pkgs, lib, ... }:
let
  # How many seconds the system should wait for the server/UPS to come back
  systemGraceTime = "120";

  upssched-dispatch = pkgs.writeShellApplication {
    name = "upssched-dispatch";
    runtimeInputs = [ pkgs.logger ];
    text =
      # bash
      ''
        # This script should be called by upssched via the CMDSCRIPT directive.
        # The first argument passed to your CMDSCRIPT is the name of the timer from your AT lines or the value of EXECUTE directive
        case $1 in
          halt)
            logger -t upssched-dispatch "Got the halt event"
            # ${pkgs.systemd}/bin/shutdown now
            ;;
          *)
            logger -t upssched-dispatch "Unrecognized command: $1"
        		;;
        esac
      '';
  };
in
{
  power.ups.schedulerRules =
    lib.pipe
      # help:
      # https://networkupstools.org/docs/man/upssched.conf.html
      ''
        CMDSCRIPT ${lib.getExe upssched-dispatch}

        PIPEFN /var/state/ups/upssched.pipe
        LOCKFN /var/state/ups/upssched.lock
        # Syntax:
        # AT <notifyType> <upsName> <command>
        AT ONLINE * CANCEL-TIMER halt

        # If UPS is on battery -- start countdown timer and die
        AT ONBATT * START-TIMER halt ${systemGraceTime}
        # Just halt on low battery
        AT LOWBATT * EXECUTE halt
        # Halt on forced shutdown
        AT FSD * EXECUTE halt

        # Comms restored -- cancel the timer just in case
        AT COMMOK * CANCEL-TIMER halt
        # If communication to the server is lost -- start countdown timer and die
        AT COMMBAD * START-TIMER halt ${systemGraceTime}

        # Do nothing, this will be caught by monitoring
        AT REPLBATT * EXECUTE REPLBATT

        AT NOCOMM * START-TIMER halt ${systemGraceTime}

        # This will log the state as unknown command
        # I might want to catch this using monitoring
        AT NOPARENT * EXECUTE NOPARENT
        AT CAL * EXECUTE CAL
        AT NOTCAL * EXECUTE NOTCAL
        AT OFF * EXECUTE OFF
        AT NOTOFF * EXECUTE NOTOFF
        AT BYPASS * EXECUTE BYPASS
        AT NOTBYPASS * EXECUTE NOTBYPASS
        AT SUSPEND_STARTING * EXECUTE SUSPEND_STARTING
        AT SUSPEND_FINISHED * EXECUTE SUSPEND_FINISHED
      ''
      [
        (pkgs.writeText "upssched.conf")
        toString
      ];

}
