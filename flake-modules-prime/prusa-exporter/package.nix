{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "prusa_exporter";
  version = "2.0.0";

  src = fetchFromGitHub {
    owner = "pubeldev";
    repo = pname;
    rev = "${version}";
    hash = "sha256-JkQzkJr9fCTVij1XSiqbltwXGJYcsBf5WYsbuTx45Ek=";
  };

  vendorHash = "sha256-sUttG6n+wC8grkd/gprPoAEfZg0BO5Jw5No+BJfPSKI=";

  doCheck = false;

  meta = {
    description = "Prometheus exporter for Prusa3D printers - supports Prusa Link API and Syslog metrics as well as logs from printer";
    homepage = "https://github.com/pubeldev/prusa_exporter";
    mainProgram = pname;
    license = lib.licenses.agpl3Only;
  };
}
