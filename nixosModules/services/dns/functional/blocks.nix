/**
  Blocks trackers and ads.

  Uses https://github.com/StevenBlack/hosts as the underlying filter.

  Implemented as an include file for unbound that creates always_null zones.

  This method was developed before `stevenblack-blocklist` was in nixpkgs and
  relied on a flake input. Flake input method, strictly speaking, is better
  since it can be updated independently of nixpkgs. However, `pkgs-unstable`
  version seems to be tracking upstream pretty closely.
*/
{ pkgs, pkgs-unstable, ... }:
{
  services.unbound.settings.server.include =
    # This derivation converts the hosts file into an unbound zone format.
    pkgs.stdenv.mkDerivation {
      name = "blocked-hosts";

      dontUnpack = true;

      buildPhase = ''
        cat ${pkgs-unstable.stevenblack-blocklist}/hosts |
          ${pkgs.gawk}/bin/awk '{sub(/\r$/,"")} {sub(/^127\.0\.0\.1/,"0.0.0.0")} BEGIN { OFS = "" } NF == 2 && $1 == "0.0.0.0" { print "local-zone: \"", $2, ".\" always_null"}' |
          tr '[:upper:]' '[:lower:]' |
          sort -u |
          grep -v -F '"local."' > zones
      '';

      installPhase = ''
        mv zones $out
      '';
    }
    |> toString;
}
