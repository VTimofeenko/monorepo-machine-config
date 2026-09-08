{
  pkgs-unstable,
  lib,
  config,
  ...
}:
let
  homeBoxPkg = pkgs-unstable.homebox;
in
{
  services.homebox.enable = true;

  services.homebox.package =
    assert lib.assertMsg (lib.versionOlder homeBoxPkg.version "1.25.0")
      "Check if the override is still necessary";
    homeBoxPkg;

  services.homebox.settings = {
    HBOX_OPTIONS_GITHUB_RELEASE_CHECK = "false";
  };

  /**
    I left `homebox` on unstable and now it needs the new secret, otherwise start
    fails.

    `HBOX_AUTH_API_KEY_PEPPER` is injected via the secret file (key=value format).

    FIXME: 26.11: move to stable `homebox`. Use `secrets` option
  */

  systemd.services.homebox.serviceConfig.EnvironmentFile = [
    config.age.secrets.homebox-auth-api-key-pepper.path
  ];

  imports = [
    ./non-functional/sso.nix
  ];
}
