{ serviceName, ... }:
{
  Error = [
    {
      title = "Homebox login is broken";
      expr = ''absent(probe_success{resource="srv:${serviceName}"}) or probe_success{resource="srv:${serviceName}"} == 0'';
      description = "Homebox /api/v1/users/login/oidc is not redirecting to Keycloak. Either homebox is down or the OIDC provider failed to initialize at startup (restart homebox).";
    }
  ];
}
