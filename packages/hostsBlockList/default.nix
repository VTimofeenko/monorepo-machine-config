# Produces a single file to be included in unbound config that blackholes all ad domains
{ pkgs, src, ... }:
pkgs.stdenv.mkDerivation {
  name = "blocked-hosts";
  inherit src;
  dontUnpack = true;
  buildPhase = ''
    cat $src | ${pkgs.gawk}/bin/awk '{sub(/\r$/,"")} {sub(/^127\.0\.0\.1/,"0.0.0.0")} BEGIN { OFS = "" } NF == 2 && $1 == "0.0.0.0" { print "local-zone: \"", $2, ".\" always_null"}'  | tr '[:upper:]' '[:lower:]' | sort -u | grep -v -F '"local."'> zones
  '';
  installPhase = ''
    mv zones $out
  '';
}
