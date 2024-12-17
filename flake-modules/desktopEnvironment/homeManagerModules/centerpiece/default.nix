{
  imports = [
    ./impl.nix
  ];

  programs.centerpiece = {
    enable = true;
    settings = {
      # TODO: color
      plugin = {
        applications.enable = true;

        brave_bookmarks.enable = false;

        brave_history.enable = false;

        brave_progressive_web_apps.enable = false;

        clock.enable = true;

        firefox_bookmarks.enable = true;

        firefox_history.enable = true;

        git_repositories.enable = false;

        gitmoji.enable = false;

        resource_monitor_battery.enable = true;

        resource_monitor_cpu.enable = true;

        resource_monitor_disks.enable = true;

        resource_monitor_memory.enable = true;

        sway_windows.enable = false;

        system.enable = true;

        wifi.enable = false;
      };
    };
  };
}
