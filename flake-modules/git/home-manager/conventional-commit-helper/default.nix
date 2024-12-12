/**
  Package that:

  - Reads per-project list of commit categories with descriptions
  - If not in a project, displays standard categories

  "In a project" is defined by presence of $PRJ_ROOT.

  Category is separated from description by colon.
*/
{ rustPlatform, fetchFromGitHub, ... }:

let
  name = "conventional-commit-helper";
in
rustPlatform.buildRustPackage {
  inherit name;
  src = fetchFromGitHub {
    owner = "VTimofeenko";
    repo = "conventional-commit-helper";
    rev = "b542c2f5a68ddb96765eb17dfc340e0ea2485e1d";
    hash = "sha256-P0NS4qd0sfgTvtIDpPs75+CmjTgGRMh0FqtzBIqwvqE=";
  };
  cargoHash = "sha256-jO/cYmTTWjrBtFtIRwP+hM19F+6NsyGWuZzaAtSSJkc=";
  meta.mainProgram = name;
}
