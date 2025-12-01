rec {
  /**
    Dynamic function to generate implementation for a proxy for all kinds of services.

    Implementation notes:
    I am not necessarily happy about binding `config` and `lib` this way.
    However, this allows the caller code to be very simple and not bother about
    importing the resulting module.
  */
  _mkProxyVhostInner =
    netName:
    {
      serviceName,
      port,
      config,
      lib,
      extraConfig ? "", # As default `services.nginx.virtualHosts.<name>.extraConfig`
      onlyHumans ? false,
      protocol ? "http",
    }:
    let
      ipLookupFuncs = {
        lan = _: lib.homelab.getHostIpInNetwork (lib.homelab.getService serviceName).onHost "lan";
        backbone-inner = lib.homelab.getServiceInnerIP;
      };
    in
    {
      services.nginx.virtualHosts."${serviceName |> lib.homelab.getServiceFqdn}" = {
        forceSSL = true;
        inherit (config.services.homelab.ssl-proxy) listenAddresses;
        sslCertificate = config.age.secrets."ssl-cert".path;
        sslCertificateKey = config.age.secrets."ssl-key".path;
        locations."/" = {
          proxyPass = "$srv_upstream";
          proxyWebsockets = true;
          extraConfig = /* nginx */ ''
            add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
            add_header X-XSS-Protection "1; mode=block" always;
            add_header X-Frame-Options "SAMEORIGIN" always;
            add_header X-Content-Type-Options "nosniff" always;
          '';
        };
        extraConfig = /* nginx */ ''
          add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
          add_header X-XSS-Protection "1; mode=block" always;
          add_header X-Frame-Options "SAMEORIGIN" always;
          add_header X-Content-Type-Options "nosniff" always;

          set $srv_upstream "${protocol}://${serviceName |> ipLookupFuncs."${netName}"}:${port |> toString}";

          ${lib.optionalString onlyHumans (
            lib.homelab.getHumanIPs
            |> map (x: "allow ${x};") # construct allow directives in nginx
            |> lib.concatStringsSep "\n" # turn into a string
          )}
          ${extraConfig}
          ${lib.optionalString onlyHumans "deny all;"}
        '';
      };
    };

  /**
    Produces a module for my default SSL virtual host.
  */
  mkStandardProxyVHost = _mkProxyVhostInner "backbone-inner";
  mkLANProxyVHost = _mkProxyVhostInner "lan";

  /**
    Produces standard firewall rules for the local service to accept traffic from
    the SSL proxy.

    Takes the local `ports` which should be a list of
    `{ port = 1234; protocol = "udp|tcp"; }`.

    Also takes `lib` to bind the functions.
  */
  mkBackboneInnerFirewallRules =
    { lib, ports }:
    {
      # The validation is done by nftables, no need to make an extra check
      networking.firewall.extraInputRules =
        ports
        # Parse ports coming in as just int. If so – reconstruct attrset.
        # Otherwise leave the value be and let if fail later if needed.
        |> map (
          it:
          if lib.isInt it then
            {
              port = it;
              protocol = "tcp";
            }
          else
            it
        )
        # Construct the firewall rules
        |> map (
          it:
          [
            ''iifname "backbone-inner"''
            ''ip saddr { ${lib.homelab.getSSLProxyIPs |> lib.concatStringsSep ", "} }''
            ''${it.protocol} dport ${it.port |> toString} accept''
          ]
          |> builtins.concatStringsSep " "
        )
        |> lib.concatLines;
    };

  /**
    Produces a module that when imported, allows `prometheus` service and
    only that service to access a specific web path.
  */
  mkMetricsPathAllowOnlyPrometheus =
    {
      serviceName,
      metricsPath,
      # In case metrics are served by a separate process
      lib,
    }:
    let
      prometheusIP =
        "prometheus" |> lib.homelab.getServiceHost |> lib.flip lib.homelab.getHostIpInNetwork "lan";
    in
    {
      services.nginx.virtualHosts."${
        serviceName |> lib.homelab.getServiceFqdn
      }".locations.${metricsPath} =
        {
          proxyPass = "$srv_upstream";
          extraConfig = ''
            allow ${prometheusIP};
            deny all;
          '';
        };
    };
}
