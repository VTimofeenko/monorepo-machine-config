{ serviceName, ... }:
{
  Error = [
    {
      title = "FilaBridge is down";
      expr = ''absent(probe_success{resource="srv:${serviceName}"}) or probe_success{resource="srv:${serviceName}"} == 0'';
      description = "FilaBridge /healthz is failing. Prusa filament usage is not reaching Spoolman.";
    }
  ];
}
