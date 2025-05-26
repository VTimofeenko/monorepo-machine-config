# Home-manager module that configures custom swayimg module
# Source for bindings:
# https://github.com/artemsen/swayimg/blob/master/extra/swayimgrc
{
  programs.swayimg = {
    enable = true;
    settings =
      let
        deleteCmd = "exec rm -- '%'; skip_file";
      in
      {
        # Disable showing image metadata (needs >2.2 in nixpkgs-stable) [24.11]
        info.show = "no";
        "keys.viewer" = {
          n = "next_file";
          p = "prev_file";
          "Shift+Delete" = deleteCmd;
          # HJKL aliases for navigating within the image
          h = "step_left 10";
          j = "step_down 10";
          k = "step_up 10";
          l = "step_right 10";
          # Additional zoom alias
          "Shift+plus" = "zoom +10";
        };
        "keys.gallery" = {
          h = "step_left";
          j = "step_down";
          k = "step_up";
          l = "step_right";
          "Shift+Delete" = deleteCmd;
        };
      };
  };
}
