{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "filabridge";
  version = "1.4.2";

  src = fetchFromGitHub {
    owner = "sargonas";
    repo = pname;
    tag = "v${version}";
    hash = "sha256-91UqmIN1bV/g1F/Y9y3HemelH3+s9hgN1MdajNFbEEk=";
  };

  vendorHash = "sha256-eC4RdW3e4P1ywueUrdsZFuThqCRDibOlJJkm72hjJ84=";

  patches = [
    # Local: apply config and printers from FILABRIDGE_PROVISION_FILE on start
    ./declarative-provisioning.patch
  ];

  # Pure-Go sqlite driver; templates and static assets are embedded
  env.CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  # Tests spin up local HTTP servers and websocket clients
  doCheck = false;

  meta = {
    description = "Syncs Spoolman filament usage from PrusaLink (and Bambu) printers";
    homepage = "https://github.com/sargonas/filabridge";
    license = lib.licenses.gpl3Only;
    mainProgram = pname;
  };
}
