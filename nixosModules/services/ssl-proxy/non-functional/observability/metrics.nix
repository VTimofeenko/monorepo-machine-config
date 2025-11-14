/**
  Sets up a vector instance to extract upstream logs and show them as metrics and in a structured format.:
*/
{ lib, ... }:
{
  # Set up the log format for the access log
  services.nginx.commonHttpConfig = ''
     log_format vector_json escape=json '{'
        '"timestamp": "$time_iso8601",'
        '"host": "$server_addr",'
        '"client_ip": "$remote_addr",'
        '"request_method": "$request_method",'
        '"request_path": "$uri",'
        '"query_string": "$args",'
        '"request_length": $request_length,'
        '"status": $status,'
        '"body_bytes_sent": $body_bytes_sent,'
        '"http_referrer": "$http_referer",'
        '"http_user_agent": "$http_user_agent",'
        '"request_time": $request_time,'
        '"domain": "$http_host",'
        '"upstream_name": "$upstream_addr",'
        '"upstream_response_time": "$upstream_response_time",'
        '"upstream_status": "$upstream_status",'
        '"upstream_connect_time": "$upstream_connect_time",'
        '"upstream_header_time": "$upstream_header_time"'
    '}';
  '';

  # Local vector instance that will remap the access log and/or ship it for processing

  services.vector = {
    enable = true;
    settings = {
      sources.nginx-log-listener = {
        type = "syslog";
        address = "0.0.0.0:9000";
        mode = "udp"; # `nginx` can only send logs over UDP.
      };

      transforms.parse-nginx-log = {
        type = "remap";
        inputs = [ "nginx-log-listener" ];
        source =
          # vrl
          ''
            . = parse_json!(.message)

            # Discard log entries caused by prometheus querying the metrics endpoints
            # Tied to prometheus having only one IP and talking to the SSL proxy over LAN
            if .client_ip == "${lib.homelab.services.getLANIP "prometheus"}" && .request_path == "/metrics" && .status == 200 {
                abort
            }
          '';
      };

      sinks.access-logs-sink = {
        type = "vector";
        inputs = [ "parse-nginx-log" ];
        address = "${lib.homelab.services.getInnerIP "log-concentrator"}:9514";
      };
    };
  };
}
