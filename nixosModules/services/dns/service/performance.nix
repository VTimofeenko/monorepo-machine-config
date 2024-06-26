# Configures unbound performance
# Source:
# https://unbound.docs.nlnetlabs.nl/en/latest/topics/core/performance.html
_:
let
  msg-cache-size' = 100;
in
{
  services.unbound.settings.server = rec {
    num-threads = 4;
    so-reuseport = "yes";

    # Some sources recommend 2*num-threads for the below (if num-threads is divisible by 2)
    msg-cache-slabs = 2 * num-threads;
    rrset-cache-slabs = msg-cache-slabs;
    infra-cache-slabs = msg-cache-slabs;
    key-cache-slabs = msg-cache-slabs;

    rrset-cache-size = "${toString (msg-cache-size' * 2)}m";
    msg-cache-size = "${toString msg-cache-size'}m";

    so-rcvbuf = "8m";
    so-sndbuf = so-rcvbuf;
  };
}
