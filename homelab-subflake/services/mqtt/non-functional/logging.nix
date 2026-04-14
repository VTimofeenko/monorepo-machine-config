{
  services.vector.settings = {
    sources.mqtt = {
      type = "mqtt";
      host = "127.0.0.1";
      topic = "#";
    };

    transforms.mqtt-formatted = {
      type = "remap";
      inputs = [ "mqtt" ];
      source = ''
        # Drop snapshots, not needed for debugging
        if ends_with(string!(.topic), "/snapshot") {
            abort
        }

        .payload = .message
        .timestamp = .timestamp || now()

        # Ensure values match the CH table types
        .qos = int!(.qos || 0)
        .retain = int!(.retain || 0)

        # Clean up internal Vector fields before sending
        del(.message)
        del(.source_type)

      '';
    };
  };
}
