{ pkgs, self, ... }:
pkgs.testers.runNixOSTest {
  name = "test";
  nodes.machine1 =
    _: # { config, pkgs, ... }:
    {
      services.getty.autologinUser = "root";
      imports = [
        self.nixosModules.vim
        {
          programs.myNeovim.enable = true;
        }
      ];
      users.users.root.password = "hunter2";
      users.users.root.hashedPasswordFile = null;
    };
  testScript = "start_all()";
}
