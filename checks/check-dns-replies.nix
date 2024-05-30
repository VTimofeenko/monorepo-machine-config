{
  self,
  # lib, # Must be the extended lib
  ...
}:
{
  name = "check-dns-replies";

  node.specialArgs.selfPkgs = self.packages;

  # FIXME: broken with the new lib because of machine1 bindings :(
  nodes.machine1 = _: { };
  # {
  #   imports = [
  #     self.inputs.data-flake.nixosModules.default
  #     ../nixosModules/services/auth_dns
  #     ../nixosModules/services/dns
  #   ];
  #   # Test only, overrides the network specifics
  #   services.unbound.settings.server = {
  #     interface = lib.mkForce [ "127.0.0.1" ];
  #     access-control = lib.mkForce [ "127.0.0.1/8 allow" ];
  #   };
  #   environment.systemPackages = [ pkgs.dig ];
  # };

  # This test makes sure that both remaps are applied
  testScript =
    # python
    ''
      from collections import namedtuple

      Check = namedtuple("Check", ["query", "result", "category"])

      machine.wait_for_unit("unbound.service")
      machine.wait_for_unit("nsd.service")


      checks = map(Check._make, (
        ("hydrogen.home.arpa", "192.168.1.1", "home.arpa zone"),
        ("gitea.srv.vtimofeenko.com",
      """lithium.home.arpa.
      192.168.1.3""", "Custom service DNS records"),
        ("helium.mgmt.home.arpa", "10.1.1.2", "Management VPN"),
        ("doubleclick.net", "0.0.0.0", "Upstream domain blockin"),
        ("roku.com", "0.0.0.0", "Custom blocklist"),
      ))

      for check in checks:
        assert machine.execute(f"dig +short {check.query} @127.0.0.1")[1] == check.result + "\n", f"Failed: {check.category}"

    '';
}
