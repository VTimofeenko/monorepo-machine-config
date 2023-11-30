# [[file:../../new_project.org::*System greeter][System greeter:1]]
{ pkgs, ... }: {
  # System greeter:1 ends here
  # [[file:../../new_project.org::*System greeter][System greeter:2]]
  boot.kernelParams = [ "console=tty1" ];
  services.greetd = {
    enable = true;
    vt = 2;
    # System greeter:2 ends here
    # [[file:../../new_project.org::*System greeter][System greeter:3]]
    # TODO: Add launch-hyprland to user packages
    settings = {
      default_session =
        {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd ${pkgs.zsh}/bin/zsh";
          user = "greeter";
        };
    };
  };
}
# System greeter:3 ends here
