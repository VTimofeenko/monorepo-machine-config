{ pkgs, self, ... }:
pkgs.testers.runNixOSTest {
  name = "test";
  nodes.machine1 =
    _: # { config, pkgs, ... }:
    {
      services.getty.autologinUser = "alice";
      imports = [ self.inputs.home-manager.nixosModules.home-manager ];
      users.users.alice = {
        isNormalUser = true;
        password = "hunter2";
      };
      home-manager.users.alice =
        _: # { config, ... }: # config is home-manager's config, not the OS one
        {
          imports = [
            self.homeManagerModules.vim
          ];
          home.stateVersion = "23.11";
          programs.myNeovim.enable = true;
        };
    };
  testScript = "start_all()";
}
