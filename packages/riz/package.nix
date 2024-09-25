{
  fetchFromGitHub,
  rustPlatform,
}:

rustPlatform.buildRustPackage rec {
  pname = "riz";
  version = "v0.2.0-git";

  src = fetchFromGitHub {
    owner = "a-tal";
    repo = pname;
    rev = "99383bf1b4ea8e33ed1432ec8d9b3e5544eda279";
    hash = "sha256-1iH+lJrYc3AR/9tfkVn22bUgqbmffhBR0n2ou65xoCs=";
  };

  cargoHash = "sha256-VagvZcwpAMaL5C/fgmA28EpDb1eXzWGJNP4KMYJlkrQ=";

  meta = {
    description = "Wiz lights API and CLI ";
    homepage = "https://github.com/a-tal/riz";
    # No license :(
    # license = licenses.unlicense;
    # maintainers = [];
  };
}
