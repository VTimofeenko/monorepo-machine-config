# Alerts for Synology NAS
# - Enum values are from SYNOLOGY-*-MIB descriptions (1 is "Normal" everywhere)
{ selector }:
let
  # Data volumes only; "Storage Pool" free space is unallocated space, not free space
  volumeSelector = ''${selector},raidName=~"Volume.*"'';
  volFreeRatio = "raidFreeSize{${volumeSelector}} / raidTotalSize{${volumeSelector}}";
  minFreeBytesWarn = toString (50 * 1024 * 1024 * 1024); # 50 gigabytes
in
{
  Critical = [
    {
      title = "NAS down";
      expr = ''absent(up{${selector}}) or up{${selector}} == 0'';
      for = "5m";
      description = "NAS is not responding to SNMP";
    }
    {
      title = "NAS RAID degraded";
      expr = "raidStatus{${selector}} == 11 or raidStatus{${selector}} == 12";
      description = "RAID is degraded (11) or crashed (12)";
    }
    {
      title = "NAS disk failing";
      expr = "diskStatus{${selector}} >= 4 or diskHealthStatus{${selector}} >= 3";
      description = "Disk crashed, has a damaged system partition, or health is critical/failing";
    }
    {
      title = "NAS system failed";
      expr = "systemStatus{${selector}} != 1 or powerStatus{${selector}} != 1";
      description = "DSM reports system or power supply failure";
    }
  ];
  Error = [
    {
      title = "NAS fan failed";
      expr = "systemFanStatus{${selector}} != 1 or cpuFanStatus{${selector}} != 1";
    }
    {
      title = "NAS volume space critical";
      expr = "${volFreeRatio} < 0.05";
      description = "Volume has less than 5% free space";
    }
  ];
  Warning = [
    {
      title = "NAS disk health warning";
      expr = "diskHealthStatus{${selector}} == 2";
    }
    {
      title = "NAS disk bad sectors growing";
      expr = "delta(diskBadSector{${selector}}[1h]) > 0";
    }
    {
      title = "NAS temperature high";
      expr = "temperature{${selector}} > 60 or diskTemperature{${selector}} > 50";
      description = "System above 60°C or a disk above 50°C";
    }
    {
      title = "NAS volume space low";
      expr = ''
        (${volFreeRatio} < 0.20)
        and (raidFreeSize{${volumeSelector}} < ${minFreeBytesWarn})
        unless (${volFreeRatio} < 0.05)
      '';
      description = "Volume is between 80-95% full and less than 50 GiB free";
    }
  ];
  Notice = [
    {
      title = "NAS DSM upgrade available";
      expr = "upgradeAvailable{${selector}} == 1";
      for = "1d";
    }
  ];
}
