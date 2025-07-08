{ servicePort, ... }:
{
  ...
}:
{
  services.vector.settings = {
    # Has `vector` prefix to denote that it's vector-specific
    sources.vector-log-concentrator = {
      type = "vector";
      address = "0.0.0.0:${servicePort |> toString}"; # Listen on all interfaces, let firewall handle the access
    };
  };

  networking.firewall.extraInputRules = ''
    iifname "backbone-inner" tcp dport ${servicePort |> toString} accept
  '';
}
