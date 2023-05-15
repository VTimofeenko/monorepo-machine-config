pkgs:
{
  change-active-workspace = pkgs.writeShellScript "change-active-workspace"
    ''
      function clamp {
          min=$1
          max=$2
          val=$3
          ${pkgs.python3}/bin/python -c "print(max($min, min($val, $max)))"
      }

      direction=$1
      current=$2
      if test "$direction" = "down"
      then
          target=$(clamp 1 10 $(($current+1)))
          echo "jumping to $target"
          hyprctl dispatch workspace $target
      elif test "$direction" = "up"
      then
          target=$(clamp 1 10 $(($current-1)))
          echo "jumping to $target"
          hyprctl dispatch workspace $target
      fi
    '';
  get-active-workspace = pkgs.writeShellScript "get-active-workspace"
    ''
      hyprctl monitors -j | jq --raw-output .[0].activeWorkspace.id
      ${pkgs.socat}/bin/socat -u UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | stdbuf -o0 awk -F '>>|,' '/^workspace>>/{print $2}'
    '';
  get-workspaces = pkgs.writeShellScript "get-workspaces"
    ''
      spaces (){
      	WORKSPACE_WINDOWS=$(hyprctl workspaces -j | jq 'map({key: .id | tostring, value: .windows}) | from_entries')
      	seq 1 10 | ${pkgs.jq}/bin/jq --argjson windows "''${WORKSPACE_WINDOWS}" --slurp -Mc 'map(tostring) | map({id: ., windows: ($windows[.]//0)})'
      }

      spaces
      ${pkgs.socat}/bin/socat -u UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | while read -r line; do
      	spaces
      done
    '';

}
