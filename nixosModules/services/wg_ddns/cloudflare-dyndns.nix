{ lib, config, ... }:
let
  inherit (lib.homelab) getServiceConfig getSrvSecret;
  srvName = "wg_ddns";
in
{
  age.secrets.cfApifile.file = getSrvSecret srvName "cfApifile";

  services.cloudflare-dyndns = {
    enable = true;
    inherit (getServiceConfig srvName) domains;
    apiTokenFile = config.age.secrets.cfApifile.path;
  };
  # Hardening
  systemd.services.cloudflare-dyndns = {
    serviceConfig = {
      # It's a simple one-shot network service, nothing fancy
      CapabilityBoundingSet =
        "~"
        + builtins.concatStringsSep " " [
          # CapabilityBoundingSet = [
          "CAP_SYS_TIME" # Service processes may change the system clock
          "CAP_SYS_PACCT" # Service may use acct()
          "CAP_KILL" # Service may send UNIX signals to arbitrary processes
          "CAP_WAKE_ALARM" # Service may program timers that wake up the system
          "CAP_DAC_OVERRIDE" # Service may override UNIX file/IPC permission checks
          "CAP_DAC_READ_SEARCH"
          "CAP_FOWNER" # Service may override UNIX file/IPC permission checks
          "CAP_IPC_OWNER" # Service may override UNIX file/IPC permission checks
          "CAP_LINUX_IMMUTABLE" # Service may mark files immutable
          "CAP_IPC_LOCK" # Service may lock memory into RAM
          "CAP_SYS_MODULE" # Service may load kernel modules
          "CAP_SYS_TTY_CONFIG" # Service may issue vhangup()
          "CAP_SYS_BOOT" # Service may issue reboot()
          "CAP_SYS_CHROOT" # Service may issue chroot()
          "CAP_BLOCK_SUSPEND" # Service may establish wake locks
          "CAP_LEASE" # Service may create file leases
          "CAP_MKNOD" # Service may create device nodes
          "CAP_CHOWN" # Service may change file ownership/access mode/capabilities unrestricted
          "CAP_FSETID" # Service may change file ownership/access mode/capabilities unrestricted
          "CAP_SETFCAP" # Service may change file ownership/access mode/capabilities unrestricted
          "CAP_SETUID" # Service may change UID
          "CAP_SETGID" # Service may change GID identities/capabilities
          "CAP_SETPCAP" # Service may change capabilities
          "CAP_MAC_ADMIN" # Service may adjust SMACK MAC
          "CAP_MAC_OVERRIDE"
          "CAP_SYS_RAWIO" # Service has raw I/O access
          "CAP_SYS_PTRACE" # Service has ptrace() debugging abilities
          "CAP_SYS_NICE" # Service has privileges to change resource use parameters
          "CAP_SYS_RESOURCE" # Service has privileges to change resource use parameters
          "CAP_NET_ADMIN" # Service has network configuration privileges
          "CAP_NET_BIND_SERVICE" # Service has elevated networking privileges
          "CAP_NET_BROADCAST" # Service has elevated networking privileges
          "CAP_NET_RAW" # Service has elevated networking privileges
          "CAP_AUDIT_CONTROL" # Service has audit subsystem access
          "CAP_AUDIT_READ"
          "CAP_AUDIT_WRITE"
          "CAP_SYS_ADMIN" # Service has administrator privileges
          "CAP_SYSLOG" # Service has access to kernel logging
        ];
      ProtectClock = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      RestrictNamespaces =
        "~"
        + builtins.concatStringsSep " " [
          "user"
          "pid"
          "net"
          "uts"
          "mnt"
          "cgroup"
          "ipc"
        ];
      ProtectHostname = true;
      ProtectKernelTunables = true;
      ProtectHome = true;
      ProtectControlGroups = true;
      ProtectProc = true;
      PrivateUsers = true;
    };
  };
}
