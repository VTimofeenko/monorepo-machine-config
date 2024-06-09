{ fetchFromGitHub, buildHomeAssistantComponent }:
let
  owner = "krahabb";
  domain = "meross_lan";
  version = "5.2.1";
in
buildHomeAssistantComponent {
  inherit owner domain version;

  src = fetchFromGitHub {
    inherit owner;
    repo = domain;
    rev = "v${version}";
    sha256 = "sha256-lVenFLztOe3HKo2r1QG5kezV4TAiw5McBPh3RQvuF08=";
  };

  propagatedBuildInputs = [ ]; # if you get error like "paho module not found" -- add mqtt to the HA components
}
