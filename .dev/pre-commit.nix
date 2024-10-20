{
  inputs',
  lib,
  pkgs,
  ...
}:
{
  settings.hooks.emacs-elisp-autofmt = {
    enable = true;
    description = "Run emacs-elisp-autofmt";
    entry = "${lib.getExe inputs'.my-flake-modules.packages.emacs-elisp-autofmt} --fmt-style native";
    fail_fast = true;
    files = ".el$";
    language = "system";
    name = "emacs-elisp-autofmt";
    pass_filenames = true;
    require_serial = true;
  };
  settings.hooks.check-data-flake-is-not-path =
    let
      hook = pkgs.writeShellApplication {
        name = "check-data-flake-is-not-path";

        runtimeInputs = [ pkgs.jq ];

        text = # bash
          ''
            if [ "$(jq -r < flake.lock '.nodes."data-flake".original.type')" == "path" ]; then
              exit 1
            else
              exit 0
            fi
          '';
      };
    in
    {
      enable = true;
      description = "Make sure data flake is not locked to path when committing";
      entry = lib.getExe hook;
      fail_fast = true;
      files = "flake.lock";
      language = "system";
      name = "check-data-flake-is-not-path";
      pass_filenames = false;
      require_serial = true;
    };
}
