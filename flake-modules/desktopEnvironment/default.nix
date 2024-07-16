/**
  Flake-module entry point for Desktop Environment.

  It provides outputs for:

  - Checks for automatic tests
  - home-manager(?) module for installing the environment
*/
{ withSystem, self, ... }:
{
  perSystem =
    { system, ... }:
    {
      checks = withSystem system (
        { pkgs, ... }:
        {
          de-canary = pkgs.testers.runNixOSTest {
            name = "desktop-environment-canary";

            nodes.machine1 =
              { pkgs, lib, ... }:
              {
                imports = [
                  self.nixosModules.de
                  self.inputs.home-manager.nixosModules.home-manager
                ];

                # User-related configuration
                services.getty.autologinUser = "alice";
                # Force disable greet so autologin works
                services.greetd.enable = lib.mkForce false;

                users.users.alice = {
                  password = "hunter2";
                  isNormalUser = true;
                };

                home-manager.users.alice = {
                  imports = [ self.homeManagerModules.de ];

                  home.stateVersion = "24.05";
                };

                # Hyprland needs this to start
                virtualisation.qemu.options = [ "-vga none -device virtio-gpu-pci" ];
                hardware.opengl.enable = true;
                # Stub terminal emulator
                environment.systemPackages = [ pkgs.kitty ];
              };

            testScript = ''
              assert True
            '';
          };
        }
      );
    };

  flake = {
    nixosModules.de = import ./nixosModules { };
    homeManagerModules.de = import ./homeManagerModules { };
  };
}
