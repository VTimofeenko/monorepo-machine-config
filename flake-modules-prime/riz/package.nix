{
  fetchFromGitHub,
  rustPlatform,
  lib,
}:

rustPlatform.buildRustPackage rec {
  pname = "riz";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "a-tal";
    repo = pname;
    rev = "7247539d8db1941cda5ab4c67e98f5faa63c4dbd";
    hash = "sha256-1iH+lJrYc3AR/9tfkVn22bUgqbmffhBR0n2ou65xoCs=";
  };

  cargoHash = "sha256-Gl/m0zB/IqP0votmEkEAONAZuYwAB3i+wBrB9vCgfvw=";

  meta = {
    description = "Wiz lights API and CLI ";
    homepage = "https://github.com/a-tal/riz";
    license = with lib.licenses; [
      mit
      asl20
    ];
    # maintainers = [];
  };
}
