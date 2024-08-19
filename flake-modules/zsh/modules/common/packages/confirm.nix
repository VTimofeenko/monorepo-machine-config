{ writeShellApplication }:
writeShellApplication {
  name = "confirm";
  runtimeInputs = [ ];
  text = ''
    echo "Confirm executing $1 command on '$(hostname)' machine?"

    CMD=$1

    read -r reply

    if [[ "''${reply,,}" == "y" ]]; then
      "$@"
    else
      echo "Not running $CMD"
    fi
  '';
}
