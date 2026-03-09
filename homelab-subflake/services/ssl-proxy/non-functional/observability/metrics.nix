/**
  Sets up a vector instance to extract upstream logs and show them as metrics and in a structured format.:
*/
{ port }:
{ lib, ... }:
let
  vectorListenerPort = 9000;
in
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

    access_log syslog:server=localhost:${vectorListenerPort |> toString},nohostname vector_json;
  '';

  # Local vector instance that will remap the access log and/or ship it for processing

  services.vector = {
    enable = true;
    settings = {
      sources.nginx-log-listener = {
        type = "syslog";
        address = "0.0.0.0:${vectorListenerPort |> toString}";
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

      # Turn the logs into metrics
      transforms.nginx-enrich = {
        type = "remap";
        inputs = [ "parse-nginx-log" ];
        source =
          # vrl
          ''
            .status, err = to_int(.status)
            if err != null {
              log("Failed to parse status: " + err, level: "error")
              # Set a default so later logic doesn't fail
              .status = 0
            }

            .upstream_status = string(.upstream_status) ?? ""
            if is_empty(.upstream_status) || (.upstream_status == "-") {
              # Set a default so later logic doesn't fail
              .upstream_status = 0
              # This also indicates that upstream response, connect and header times are empty
              .upstream_response_time = 0
              .upstream_connect_time = 0
              .upstream_header_time = 0
            }
            .upstream_status, err = to_int(.upstream_status)
            if err != null {
              log("Failed to parse upstream_status: " + err, level: "info", rate_limit_secs: 0)
            }

            .upstream_response_time, err = to_float(.upstream_response_time)
            if err != null {
              log("Failed to parse upstream_response_time: " + err, level: "info", rate_limit_secs: 0)
            }

            .upstream_connect_time, err = to_float(.upstream_connect_time)
            if err != null {
              log("Failed to parse upstream_connect_time: " + err, level: "info", rate_limit_secs: 0)
            }

            .upstream_header_time, err = to_float(.upstream_header_time)
            if err != null {
              log("Failed to parse upstream_header_time: " + err, level: "info", rate_limit_secs: 0)
            }

            # --- Enrichment ---
            # Add a convenient label based on the (now integer) upstream_status
            if .upstream_status >= 500 {
              .upstream_result_type = "5xx_server_error"
            } else if .upstream_status >= 400 {
              .upstream_result_type = "4xx_client_error"
            } else if .upstream_status >= 200 || (.status == 301 && .upstream_status == 0) || .upstream_status == 101 {
              # 301 status with 0 upstream means nginx did the redirect
              .upstream_result_type = "2xx_3xx_success"
            } else {
              # This will catch status 0 or other NGINX-side errors (like 502s)
              # where the upstream never provided a status.
              .upstream_result_type = "nginx_error_or_other"
            }

          '';
      };

      transforms.nginx-metrics = {
        type = "log_to_metric";
        inputs = [ "nginx-enrich" ];
        metrics = [
          {
            type = "counter";
            name = "nginx_http_requests_total";
            namespace = "ssl_proxy";
            description = "Total number of HTTP requests";
            field = "domain";
            increment_by_value = false;
            tags = {
              domain = "{{ domain }}";
              upstream = "{{ upstream_name }}";
              method = "{{ request_method }}";
              status = "{{ status }}";
              upstream_status = "{{ upstream_status }}";
              result = "{{ upstream_result_type }}";
            };
          }
        ];
      };

      sinks.prometheus-exporter = {
        type = "prometheus_exporter";
        inputs = [ "nginx-metrics" ];
        address = "0.0.0.0:${port |> toString}";
      };
    };
  };

  # Allow firewall
  networking.firewall.extraInputRules = ''
    iifname "backbone-inner" ip saddr ${
      "prometheus" |> lib.homelab.getServiceInnerIP
    } tcp dport ${port |> toString} accept comment "Allow prometheus to scrape metrics"
  '';
}
