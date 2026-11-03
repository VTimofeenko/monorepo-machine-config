{ pkgs, lib, ... }:

{
  programs.gamemode.enable = true;

  programs.gamemode.settings = {
    custom =
      {
        start =
          # bash
          ''
            echo "performance" | /run/wrappers/bin/sudo ${pkgs.coreutils}/bin/tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
            ${lib.getExe pkgs.libnotify} "GameMode active"
          '';
        end = # bash
          ''
            echo "powersave" | /run/wrappers/bin/sudo ${pkgs.coreutils}/bin/tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
            ${lib.getExe pkgs.libnotify} "GameMode disabled"
          '';
      }
      |> lib.mapAttrs (_: v: v |> pkgs.writeShellScript "runme" |> toString);
  };

  # Ensure your user is in the gamemode group
  users.users.spacecadet.extraGroups = [ "gamemode" ];

  # This allows gamemoded to run its internal scripts without a password prompt
  security.polkit.enable = true;

  # Specifically allow the EPP changes without sudo password
  security.sudo.extraRules = [{
    users = [ "spacecadet" ];
    commands = [{
      command = "${pkgs.coreutils}/bin/tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference";
      options = [ "NOPASSWD" ];
    }];
  }];
}
