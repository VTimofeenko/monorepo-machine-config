/**
  Package that:

  - Reads per-project list of commit categories with descriptions
  - If not in a project, displays standard categories

  "In a project" is defined by presence of $PRJ_ROOT.

  Category is separated from description by colon.
*/
{ rustPlatform, ... }:

let
  name = "semantic-commit-type-helper";
in
rustPlatform.buildRustPackage {
  inherit name;
  src = ./src;
  version = "1.0.0";
  cargoHash = "sha256-IiJjOBII2XawfdaY9eVZrGlD7Tm7ivnuq5Zl2usA81g=";
  meta.mainProgram = name;
}
