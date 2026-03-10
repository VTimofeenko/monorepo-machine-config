{ lib, ... }:
{
  services.openssh = {
    enable = true;
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
    settings.PermitRootLogin = "yes";
  };
  users.users.root.openssh.authorizedKeys.keys = lib.homelab.getSettings.SSHKeys;

  environment.persistence."/persist".files = [ "/etc/ssh/ssh_host_ed25519_key" ];

  networking.firewall.interfaces =
    [
      "phy-lan"
      "backbone"
    ]
    |> map (it: {
      it.allowedTCPPorts = [ 22 ];
    })
    |> lib.mergeAttrsList;
}
