/**
  Implementation notes:

  - Using paths under `/run/current-system/` allows `tuigreet` to safely handle
    generation changes
  - Downside — implicitly depends on `zsh`/`niri`
  - Does not allow autologin
  - `/run/current-system/sw/share/wayland-sessions` does not exist by
    default — NixOS's default `environment.pathsToLink` only links a
    curated subset of `/share`, and `wayland-sessions` isn't in it, even
    though `niri`/`zshDesktopSession` are in `environment.systemPackages`.
    Opt it in explicitly.
*/
{ pkgs, ... }:
let
  zshDesktopSession = pkgs.writeTextFile {
    name = "zsh-session";
    destination = "/share/wayland-sessions/zsh.desktop";
    text = ''
      [Desktop Entry]
      Name=Zsh (Console)
      Comment=Direct Zsh terminal session
      Exec=/run/current-system/sw/bin/zsh -l
      Type=Application
    '';
  };
in
{
  environment.systemPackages = [ zshDesktopSession ];
  environment.pathsToLink = [ "/share/wayland-sessions" ];

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = ''
          ${pkgs.tuigreet}/bin/tuigreet \
            --time \
            --remember \
            --remember-user-session \
            --sessions /run/current-system/sw/share/wayland-sessions
        '';
        user = "greeter";
      };
    };
  };
}
