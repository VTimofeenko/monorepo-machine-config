/**
  Config for log shipping, implemented using vector.dev.
*/
{
  ...
}:
{
  services.vector = {
    enable = true;
    settings = {
      sources = {
        local-journal.type = "journald";
        local-journal-nixos = {
          type = "journald";
          include_matches.SYSLOG_IDENTIFIER = [ "nixos" ];
        };
      };
      /**
        This transformation parses NixOS switch events in journald
         and emits filtered data with the target version and status
      */
      transforms.parse-nixos-events = {
        type = "remap";
        inputs = [ "local-journal-nixos" ];
        source = # vrl
          ''
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
    };
    journaldAccess = true;
  };
}
