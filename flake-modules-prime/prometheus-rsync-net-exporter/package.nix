{
  rustPlatform,
  fetchFromGitea,
  openssl,
  pkg-config,
  ...
}:
let
  version = "1.1.0";
in
rustPlatform.buildRustPackage rec {
  name = "prometheus-rsync-net-exporter";
  src = fetchFromGitea {
    domain = "gitea.srv.vtimofeenko.com";
    owner = "spacecadet";
    repo = "prometheus-rsync-net-exporter-rs";
    tag = "v${version}";
    hash = "sha256-1jESS10dQWnIFob3xNzXALoJlET0tcVguKsLQD2YbBQ=";
  };
  cargoHash = "sha256-ClAWk8UJUyekdPQ5xhlDXrY+cvt1wJ6Rm9cvc5CBiRU=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  meta.mainProgram = name;
}
