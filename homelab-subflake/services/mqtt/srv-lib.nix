_: {
  /**
    `deployment-event <started|finished|failed>`: publishes a deployment of
    `target` (`srv:<name>`, a host) to `homelab/deployments/<target>`, for
    deployments that are not a NixOS switch. Never fails the caller. Takes the
    caller's `lib`: the one srv-libs are imported with has no manifests.

    ```
    runtimeInputs = [ (mkDeploymentEvent { inherit lib pkgs; } { target = "srv:${srvName}"; inherit (config.system.nixos) label; }) ];
    ```
  */
  mkDeploymentEvent =
    { lib, pkgs }:
    { target, label }:
    pkgs.writeShellApplication {
      name = "deployment-event";
      runtimeInputs = with pkgs; [
        coreutils
        jq
        mosquitto
      ];
      text = ''
        payload=$(jq -nc --arg event "$1" --arg from "$(uname -n)" \
          '{target: "${target}", version: "${label}", $event, $from}')
        timeout 10 mosquitto_pub -q 1 \
          -h ${lib.homelab.getServiceFqdn "mqtt"} -p ${
            (lib.homelab.getManifest "mqtt").endpoints.mqtt.port |> toString
          } \
          --cafile ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt \
          -t "homelab/deployments/${target}" -m "$payload" \
          || echo "Could not publish the deployment event" >&2
      '';
    };
}
