/**
  Parses incoming logs, looking for deployment events. If there are any –
  sends them down a separate path.
*/
{
  services.vector.settings.transforms.events-deployments = {
    type = "remap";
    inputs = [ "vector-log-concentrator" ];
    source =
      # vrl
      ''
        # Discard non-nixos messages
        if .SYSLOG_IDENTIFIER != "nixos" {
          abort
        }

        # Skip the "starting" message
        .message = string!(.message)
        if contains(.message, "switching to") && !contains(.message, "(status") && !contains(.message, "finished") {
            abort
        }

        # Extract target version and status of switch
        # .*? is non-greedy match for hostname
        target_version = parse_regex!(.message, r'.*nixos-system-.*?-(?P<version>[^ ]*)').version
        status = parse_regex(.message, r'status (?P<status>\d)').status ?? 0

        # Store needed values
        host = .host
        ts = .timestamp  # "timestamp" is reserved

        # clear the object
        del(.)

        # Reconstruct the values
        .target_version = target_version
        .host = host
        .timestamp = ts
        .status = status

      '';
  };
}
