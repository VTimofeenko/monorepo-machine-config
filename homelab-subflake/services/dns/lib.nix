# DNS-specific functions
rec {
  mkRecord =
    recordType: domainName: recordValue:
    "${domainName} IN ${recordType} ${recordValue}";
  mkARecord = mkRecord "A";
  mkCNAMERecord = domainName: recordValue: (mkRecord "CNAME" domainName (recordValue + "."));
}
