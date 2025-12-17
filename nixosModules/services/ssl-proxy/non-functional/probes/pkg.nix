{
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "ssl_exporter";
  version = "2.4.3";

  src = fetchFromGitHub {
    owner = "ribbybibby";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-3BIbdwtX/2On6D96hTr3aafkLvg8glLcsxHWYJVOPZE=";
  };

  vendorHash = "sha256-+qAi2OmGGDQx3aNCOPivMgw5+6bhnQ7Zi6bPK+4kEpE=";

  doCheck = false;

  meta.mainProgram = "ssl_exporter";
}

