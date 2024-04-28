/**
  This machine has some weird bug which causes one CPU to be ~60% occupied by a kworker/kacipd.

  A workaround is to disable that interrupt. This hasn't (so far) caused any problems but I honestly
  have no idea. Very experimental, don't use in a random copypaste.
*/
{ pkgs, lib, ... }:
let
  disableInterruptScript = pkgs.writeShellApplication {
    name = "disable-buggy-interrupt";
    runtimeInputs = [
      pkgs.gnugrep
      pkgs.coreutils-full
      pkgs.gawk
    ];
    text = ''
      INTERRUPT_TARGET=$(grep -Ev '^[ ]*0'  /sys/firmware/acpi/interrupts/gpe?? | sort --field-separator=: --key=2 --numeric --reverse | head -1 | awk -F: '{print $1}')
      echo disable > "$INTERRUPT_TARGET"
    '';
  };
in
{
  systemd.services.disable-buggy-interrupt = {
    enable = true;
    description = "Kill CPU-hogging interrupt";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe disableInterruptScript;
    };
    wantedBy = [ "multi-user.target" ];
  };
}
