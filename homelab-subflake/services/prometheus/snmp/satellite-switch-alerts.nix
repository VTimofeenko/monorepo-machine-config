# Alerts for MikroTik satellite switch
# - No availability alert: the switch being offline is expected for now; all rules need fresh data to fire
# - Enum values are from MIKROTIK-MIB (via upstream snmp.yml)
# - No fan alert: fans spin down when idle; overheating is caught by the temperature alert
{ selector }:
{
  # Enable once the switch has a permanent location
  # Critical = [
  #   {
  #     title = "Switch dead";
  #     expr = ''absent(up{${selector}}) or up{${selector}} == 0'';
  #     for = "5m";
  #     description = "Switch is not responding to SNMP";
  #   }
  # ];
  Error = [
    {
      title = "Switch PoE port fault";
      # 4..10: overload, shortCircuit, voltageTooLow, currentTooLow, powerReset, voltageTooHigh, controllerError
      expr = "mtxrPOEStatus{${selector}} >= 4 and mtxrPOEStatus{${selector}} <= 10";
      description = "PoE port reports a fault";
    }
  ];
  Warning = [
    {
      title = "Switch temperature high";
      expr = ''mtxrGaugeValue{${selector},mtxrGaugeName=~".*temperature.*"} > 70'';
    }
    {
      title = "Switch port FCS errors";
      expr = "rate(mtxrInterfaceStatsRxFCSError{${selector}}[10m]) > 0";
      for = "15m";
      description = "Port keeps receiving frames with bad checksums, likely a bad cable or connector";
    }
  ];
}
