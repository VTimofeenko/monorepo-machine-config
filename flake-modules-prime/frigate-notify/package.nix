/**
  A forked version of `frigate-notify` that adds a few features and removes Olm dependency.
*/
{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "frigate-notify";
  version = "0.5.4";

  src = fetchFromGitHub {
    owner = "VTimofeenko";
    repo = pname;
    rev = "10430798fd19a383af3fc19905e5ebd36632f318";
    hash = "sha256-fsjtFFxW0UBqSJILxuSUar7xWAK8GzAnd/LlKrkmKyg=";
  };

  vendorHash = "sha256-rS4g6N9GVgGiV1pdJzH0rnOPhgF46ewOAX6oVG4Zoqs=";

  doCheck = false; # it tries to perform some tests that require frigate

  meta = with lib; {
    description = "A simple app designed to send notifications from Frigate NVR to your favorite platforms";
    homepage = "https://github.com/0x2142/frigate-notify";
    license = licenses.mit;
    mainProgram = "frigate-notify";
    maintainers = with maintainers; [ vtimofeenko ];
  };
}
