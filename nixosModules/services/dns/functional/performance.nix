# Configures unbound performance
# Source:
# https://unbound.docs.nlnetlabs.nl/en/latest/topics/core/performance.html
_:
let
  msg-cache-size' = 128;
  bufSizeMB = 8;
in
{
  services.unbound.settings.server = rec {
    num-threads = 4;
    so-reuseport = "yes";

    # Some sources recommend 2*`num-threads` for the below (if `num-threads` is divisible by 2)
    msg-cache-slabs = 2 * num-threads;
    rrset-cache-slabs = msg-cache-slabs;
    infra-cache-slabs = msg-cache-slabs;
    key-cache-slabs = msg-cache-slabs;

    num-queries-per-thread = 1024;
    outgoing-range = 4096;
    incoming-num-tcp = 25;
    outgoing-num-tcp = 25;

    rrset-cache-size = "${toString (msg-cache-size' * 2)}m";
    msg-cache-size = "${toString msg-cache-size'}m";

    so-rcvbuf = "${bufSizeMB |> toString}m";
    so-sndbuf = so-rcvbuf;
  };

  # Set the `sysctl` values
  boot.kernel.sysctl."net.core.rmem_max" = bufSizeMB * 1024 * 1024;
  boot.kernel.sysctl."net.core.wmem_max" = bufSizeMB * 1024 * 1024;
}
