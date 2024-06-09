/**
  Configures:

  - dnstap logging for unbound ( http://dnstap.info )
  - vector ingestion of dnstap logs ( https://vector.dev/docs/reference/configuration/sources/dnstap/ )

  Also sets up a mapping between hostnames and IPs that vector does on the fly.
*/
{ pkgs, lib, ... }:
let

  loggingConfig = lib.homelab.getServiceLogging "dns";
in
{
  services = {
    unbound = {
      # Enable dnstap support
      package = pkgs.unbound-full;
      # Dnstap logging for unbound
      # https://unbound.docs.nlnetlabs.nl/en/latest/manpages/unbound.conf.html#dnstap-logging-options
      settings.dnstap = {
        dnstap-enable = true;
        dnstap-ip = "127.0.0.1@9000";
        dnstap-tls = false;
        # dnstap-socket-path = config.systemd.sockets.vector.socketConfig.ListenFIFO;

        # Log all messages for now
        # Enable to log resolver query messages. These are messages from Unbound to upstream servers.
        dnstap-log-resolver-query-messages = false;

        # Enable to log resolver response messages. These are replies from upstream servers to Unbound.
        dnstap-log-resolver-response-messages = false;

        # Enable to log client query messages. These are client queries to Unbound.
        dnstap-log-client-query-messages = false;

        # Enable to log client response messages. These are responses from Unbound to clients.
        dnstap-log-client-response-messages = true;

        # Enable to log forwarder query messages.
        dnstap-log-forwarder-query-messages = false;

        # Enable to log forwarder response messages.
        dnstap-log-forwarder-response-messages = false;
      };
    };

    vector = {
      settings = {
        sources = {
          local-dnstap = {
            type = "dnstap";
            address = "127.0.0.1:9000";
            mode = "tcp";
            socket_path = ""; # fake, but needed for schema
          };
        };
        transforms.add_hostname_to_dnstap_data = {
          type = "remap";
          inputs = [ "local-dnstap" ];
          source = ''
            sourceAddress, err = get(value: . , path: ["sourceAddress"] )
            if err != null {
              log("Unable to find sourceAddress: " + err, level: "error")
            } else {
              row = get_enrichment_table_record("my-data", {"ip" : sourceAddress}, ["hostname"]).hostname ?? "Unknown"

              .matched_name = row
            }

            # Extract the query
            # Usually there is one for the message types I am interested in
            # More robust way would be to do like a pluck or catAttrs, but YOLO
            .my_query = .responseData.question[0].domainName
            .my_answer = .responseData.answers[0].rData
          '';
        };
        sinks = {
          dnstap-sink = {
            type = "kafka";
            # inputs = [ "local-dnstap" ];
            inputs = [ "add_hostname_to_dnstap_data" ];
            encoding.codec = "json"; # TODO: protobuf?

            # bootstrap_servers = "${service.fqdn}:9092"; # TODO: fix the network resolution in this vpn
            bootstrap_servers = "10.5.0.7:9092";
            topic = loggingConfig.topicName;
          };
        };
      };
    };
  };

  # Debug mode
  # systemd.services.vector.serviceConfig.Environment = [ "VECTOR_LOG=debug" ];
}
