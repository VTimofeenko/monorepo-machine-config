{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    htop
    curl
    wget
    fd
    inetutils # for telnet
    lsof
    dig
    nftables
    unzip
    tcpdump
    jq
  ];
}
