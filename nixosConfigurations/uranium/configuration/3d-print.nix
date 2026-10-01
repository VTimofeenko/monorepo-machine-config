{ pkgs, ... }:
let
  scad-render = pkgs.writeShellApplication {
    name = "scad-render";
    runtimeInputs = [
      pkgs.xvfb-run
      pkgs.openscad
    ];
    text = ''
      has_scheme=0
      has_size=0
      for arg in "$@"; do
        case "$arg" in
          --colorscheme*|-c*) has_scheme=1 ;;
          --imgsize*) has_size=1 ;;
        esac
      done

      extra_args=()
      if [ "$has_scheme" -eq 0 ]; then
        extra_args+=("--colorscheme=Tomorrow")
      fi
      if [ "$has_size" -eq 0 ]; then
        extra_args+=("--imgsize=1024,1024")
      fi

      exec xvfb-run -a openscad "''${extra_args[@]}" "$@"
    '';
  };
in
{
  environment.systemPackages = [
    pkgs.openscad
    pkgs.prusa-slicer
    pkgs.xvfb-run
    scad-render
  ];
  fonts = {
    packages =
      {
        inherit (pkgs) roboto twitter-color-emoji font-awesome;
        inherit (pkgs.nerd-fonts) jetbrains-mono;
        inherit (pkgs) goldman good-timings russo-one; # My fonts
      }
      |> builtins.attrValues;
    fontconfig = {
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font" ];
        sansSerif = [ "Roboto" ];
        serif = [ "Roboto" ];
        emoji = [ "Twitter Color Emoji" ];
      };
    };
  };
}
