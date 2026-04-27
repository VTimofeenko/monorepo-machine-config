{
  services.homebox.enable = true;

  services.homebox.settings = {
    HBOX_OPTIONS_GITHUB_RELEASE_CHECK = "false";
  };

  imports = [
    ./non-functional/sso.nix
  ];
}
