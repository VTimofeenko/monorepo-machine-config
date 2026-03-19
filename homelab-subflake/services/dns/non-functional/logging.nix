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

      settings.server.log-servfail = "yes";

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
        sinks = {
          dnstap-new-sink = {
            type = "vector";
            inputs = [ "local-dnstap" ];
            address = "${lib.homelab.getServiceInnerIP "log-concentrator"}:${
              "log-concentrator" |> lib.homelab.getServiceConfig |> builtins.getAttr "dnstapPort" |> toString
            }";
          };
        };
      };
    };
  };

  # Debug mode
  # systemd.services.vector.serviceConfig.Environment = [ "VECTOR_LOG=debug" ];
}
