mkModeBinding:
{
  pkgs,
  config,
  lib,
  ...
}:
let
  pass-selector = pkgs.writeShellApplication {
    name = "pass-selector";
    runtimeInputs = [
      pkgs.bemenu
      pkgs.fd
      pkgs.fzf
      pkgs.libnotify
      config.programs.password-store.package
    ];
    text = ''
      # NOTE: Revert to global mode even if input is canceled
      hyprctl dispatch submap reset
      export BEMENU_BACKEND="wayland"

      PASSWORD=$(fd .gpg "$PASSWORD_STORE_DIR" \
          --exclude "otp/" \
          | sed 's/.gpg$//' \
          | sed "s;''${PASSWORD_STORE_DIR}/;;" \
          | bemenu --list 10 \
          --width-factor 0.2 \
          --prompt "pass ❯")

      pass -c "$PASSWORD"

      notify-send --icon password "Copied $PASSWORD"
    '';
  };
  pass-otp-selector = pkgs.writeShellApplication {
    name = "pass-otp-selector";
    runtimeInputs = [
      pkgs.bemenu
      pkgs.fd
      pkgs.fzf
      pkgs.libnotify
      config.programs.password-store.package
    ];
    text = ''
      # NOTE: Revert to global mode even if input is canceled
      hyprctl dispatch submap reset
      export BEMENU_BACKEND="wayland"

      PASSWORD=$(fd .gpg "$PASSWORD_STORE_DIR/otp" \
          | sed 's/.gpg$//' \
          | sed "s;''${PASSWORD_STORE_DIR}/otp/;;" \
          | bemenu --list 10 \
          --width-factor 0.2 \
          --prompt "otp ❯")

      pass otp -c "otp/$PASSWORD"

      notify-send --icon password "Copied OTP $PASSWORD"
    '';
  };
in
mkModeBinding ",Alt_R" "leader" ''
  bind = , P, exec, ${lib.getExe pass-selector}
  bind = , O, exec, ${lib.getExe pass-otp-selector}
''
