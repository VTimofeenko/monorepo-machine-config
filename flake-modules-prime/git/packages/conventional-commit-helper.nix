{
  rustPlatform,
  fetchFromGitHub,
  lib,
}:
rustPlatform.buildRustPackage rec {
  pname = "conventional-commit-helper";
  version = "3.0.0";

  src = fetchFromGitHub {
    owner = "VTimofeenko";
    repo = "conventional-commit-helper";
    rev = version;
    hash = "sha256-1VP4enocbVbbPREBzfkBxdA/kKfFObJxLWFJ3KXG7bM=";
  };

  cargoHash = "sha256-txASrxrsCNo9WY3axxeEgO9AclnFC+ARHyOZ7fKZUCk=";

  meta = {
    description = "A helper for conventional commits";
    homepage = "https://github.com/VTimofeenko/conventional-commit-helper";
    license = lib.licenses.mit;
    mainProgram = "conventional-commit-helper";
  };
}
