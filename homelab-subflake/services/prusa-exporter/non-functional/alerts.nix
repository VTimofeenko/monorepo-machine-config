{ serviceName, ... }:
{
  Warning = [
    {
      title = "Chamber temp PLA heat creep risk";
      expr = ''
        prusa_chamber_temp{resource="srv:${serviceName}"} > 35
        and on(resource)
        (time() - prusa_last_push_timestamp{resource="srv:${serviceName}"}) < 120
        and on(resource)
        prusa_material_info{resource="srv:${serviceName}", printer_filament="PLA"} == 1
      '';
      description = "Chamber temperature has been above 35°C for 10+ minutes while printing PLA — heat creep risk";
      for = "10m";
    }
    {
      title = "Chamber temp PETG heat creep risk";
      expr = ''
        prusa_chamber_temp{resource="srv:${serviceName}"} > 45
        and on(resource)
        (time() - prusa_last_push_timestamp{resource="srv:${serviceName}"}) < 120
        and on(resource)
        prusa_material_info{resource="srv:${serviceName}", printer_filament="PETG"} == 1
      '';
      description = "Chamber temperature has been above 45°C for 10+ minutes while printing PETG — heat creep risk";
      for = "10m";
    }
  ];
  Critical = [
    {
      title = "Chamber temp PLA heat creep imminent";
      expr = ''
        prusa_chamber_temp{resource="srv:${serviceName}"} > 40
        and on(resource)
        (time() - prusa_last_push_timestamp{resource="srv:${serviceName}"}) < 120
        and on(resource)
        prusa_material_info{resource="srv:${serviceName}", printer_filament="PLA"} == 1
      '';
      description = "Chamber temperature above 40°C while printing PLA — heat creep clog likely imminent";
      for = "5m";
    }
    {
      title = "Chamber temp PETG heat creep imminent";
      expr = ''
        prusa_chamber_temp{resource="srv:${serviceName}"} > 50
        and on(resource)
        (time() - prusa_last_push_timestamp{resource="srv:${serviceName}"}) < 120
        and on(resource)
        prusa_material_info{resource="srv:${serviceName}", printer_filament="PETG"} == 1
      '';
      description = "Chamber temperature above 50°C while printing PETG — heat creep clog likely imminent";
      for = "5m";
    }
  ];
}
