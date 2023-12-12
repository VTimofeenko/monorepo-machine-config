# Configures logging for the firewall
{ pkgs, config, ... }:
let
  srvName = "wan_firewall";
  inherit (config) my-data;
  thisSrvConfig = my-data.lib.getServiceConfig srvName;
in
{
  services.ulogd.enable = true;
  environment.systemPackages = [ pkgs.ulogd ];
  services.ulogd.settings = {
    global = {
      # TODO: move to service settings
      stack = builtins.concatStringsSep "," [
        "log1:NFLOG" # Capture from nflog group
        "base1:BASE" # No idea
        "pcap1:PCAP"
        "ifi1:IFINDEX" # No idea, but without this and the next one ulogd refuses to start
        "ip2str1:IP2STR" # See above
        "print1:PRINTPKT" # Needed to literally "print" to...
        "sys1:SYSLOG" # Syslog!
      ];
    };
    log1 = {
      inherit (thisSrvConfig.logging.journaldAndPCAP) group;
    };
    pcap1 = {
      file = thisSrvConfig.logging.journaldAndPCAP.pcapFile;
      sync = 1;
    };
    sys1 = {
      facility = "LOG_LOCAL1";
    };
  };
}
