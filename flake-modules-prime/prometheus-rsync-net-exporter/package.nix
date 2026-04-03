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
    # tag = version;
    rev = "8b0f1479d6c49674d55bca21f7ec432cdf8a1d12";
    hash = "sha256-j3CM8z5A/LwBOKi0KmWyTR1c/+8uk03F7QqGCIVuDsY=";
  };
  cargoHash = "sha256-8AuXXHge3DuXjN0KdI0b2hu/pzbPq4WpNLNIwY12f8I=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  meta.mainProgram = name;
}
