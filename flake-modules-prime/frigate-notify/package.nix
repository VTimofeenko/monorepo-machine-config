{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "frigate-notify";
  version = "0.5.3";

  src = fetchFromGitHub {
    owner = "0x2142";
    repo = pname;
    tag = "v${version}";
    hash = "sha256-VYDfnEITQcLGld2yYvBUdS2Xw1x4TuH+qTjlVVEP5+8=";
  };

  vendorHash = "sha256-miBOrWqzpuxJGj8g2kdn1Jgv0r42f2vMr47usYXFsJU=";

  doCheck = false;  #  it tries to perform some tests that require frigate

  patches = [ ./remove-olm.patch ];

  meta = with lib; {
    description = "A simple app designed to send notifications from Frigate NVR to your favorite platforms";
    homepage = "https://github.com/0x2142/frigate-notify";
    license = licenses.mit;
    mainProgram = "frigate-notify";
    maintainers = with maintainers; [ vtimofeenko ];
  };
}
