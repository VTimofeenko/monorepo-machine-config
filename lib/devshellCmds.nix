# Devshell commands to check various things
{ pkgs, ... }:
[
  {
    help = "Check the DNS replies";
    name = "check-dns";
    command =
      let
        checkScript = pkgs.writeShellApplication {
          name = "check-dns";
          runtimeInputs = builtins.attrValues { inherit (pkgs) dig; };
          text = # bash
            ''
              set -euo pipefail

              test_list=( hydrogen.home.arpa google.com gitea.srv.vtimofeenko.com helium.mgmt.home.arpa doubleclick.net roku.com )
              dns_servers=( helium.home.arpa hydrogen.home.arpa )

              for dns in "''${dns_servers[@]}"; do
                echo "Checking $dns"
                for i in "''${test_list[@]}"; do

                echo "$i"
                dig +short "$i" @"$dns"

                done
              done
            '';
        };
      in
      pkgs.lib.getExe checkScript;
  }
]
# `flake management`, next to my-flake-modules' `flake-bump-<input>`
++ (
  let
    flakeBump = pkgs.lib.getExe (
      pkgs.writeShellApplication {
        name = "flake-bump";
        runtimeInputs = builtins.attrValues {
          inherit (pkgs)
            git
            jq
            gnused
            gnugrep
            ;
        };
        text = builtins.readFile ../devshell/flake-bump.sh;
      }
    );
  in
  map (c: c // { category = "flake management"; }) [
    {
      name = "flake-bump-nixpkgs";
      help = "Bump nixpkgs and home-manager in both flakes, one commit (--release YY.MM moves release)";
      command = "${flakeBump} nixpkgs \"$@\"";
    }
    {
      name = "flake-bump-nixpkgs-unstable";
      help = "Bump nixpkgs-unstable in both flakes, one commit";
      command = "${flakeBump} nixpkgs-unstable";
    }
    {
      name = "flake-bump-all-inputs";
      help = "Bump every input in both flakes, one commit";
      command = "${flakeBump} all";
    }
  ]
)
