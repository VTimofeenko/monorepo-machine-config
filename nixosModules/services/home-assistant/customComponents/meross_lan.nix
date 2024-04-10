{ fetchFromGitHub, buildHomeAssistantComponent }:
let
  owner = "krahabb";
  domain = "meross_lan";
  version = "5.0.3";
in
buildHomeAssistantComponent {
  inherit owner domain version;

  src = fetchFromGitHub {
    inherit owner;
    repo = domain;
    rev = "v${version}";
    sha256 = "sha256-+sAwwDG+LT4dGERWlctjqXXdIHFe2xv1PQchGQhb5fA=";
  };

  propagatedBuildInputs = [ ]; # if you get error like "paho module not found" -- add mqtt to the HA components
}
