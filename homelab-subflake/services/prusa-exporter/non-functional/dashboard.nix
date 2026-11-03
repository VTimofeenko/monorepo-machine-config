{ pkgs, ... }:
{
  environment.etc."grafana-dashboards/prusa/prusa-core-one.json".source =
    pkgs.runCommand "prusa-core-one-dashboard.json" { } ''
      cp ${./dashboard.json} $out
    '';
}
