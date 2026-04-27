{ pkgs-unstable, lib, ... }:
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

  imports = [
    ./non-functional/sso.nix
  ];
}
