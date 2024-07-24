{ inputs', lib, ... }:
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
}
