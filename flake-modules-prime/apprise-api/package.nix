/**
  `apprise-api` python package.

  Package is modeled after `netbox` since they are both Django apps.

  Upstream pins dependencies that are newer than nixpkgs, so they are
  overridden in a private python package set. Bump them together with the
  package: see `requirements.txt` of the new tag.
*/

{
  python3,
  fetchFromGitHub,
}:
let
  python = python3.override {
    self = python;
    packageOverrides = pyFinal: pyPrev: {
      # Upstream wants `django >= 6.1.3, < 7`
      django = pyPrev.django_6.overridePythonAttrs rec {
        version = "6.1.3";
        src = pyFinal.fetchPypi {
          pname = "django";
          inherit version;
          hash = "sha256-tdLZ41KVBl0TsZJ7Pxmlm9EZ9zeqYpne8UzMoa48jA0=";
        };
        doCheck = false;
      };
      # Upstream pins `apprise == <version>`
      apprise = pyPrev.apprise.overridePythonAttrs rec {
        version = "2.3.0";
        src = pyFinal.fetchPypi {
          pname = "apprise";
          inherit version;
          hash = "sha256-NZs3Mgy3zRaaV6R1NGv+rM21B0swfGq6o697YnkLG1I=";
        };
        doCheck = false; # YOLO
      };
      dateblock = pyFinal.buildPythonPackage rec {
        pname = "dateblock";
        version = "2.2.0";
        pyproject = true;
        src = pyFinal.fetchPypi {
          inherit pname version;
          hash = "sha256-d7NssQ3GkC/Cxou/7qOUbIofkPHwIQ+4G6FzDzxSOpc=";
        };
        build-system = [ pyFinal.setuptools ];
      };
    };
  };
  python3Packages = python.pkgs;
in
python3Packages.buildPythonApplication rec {
  pname = "apprise-api";
  version = "2.2.0";

  src = fetchFromGitHub {
    owner = "caronc";
    repo = "apprise-api";
    tag = "v${version}";
    hash = "sha256-rfrHj+hNIdfy6QUCcHrAv0Sdl3IU91I6tpyThVTCqek=";
  };

  pyproject = true;
  build-system = with python3Packages; [
    setuptools
  ];

  dependencies = with python3Packages; [
    apprise
    django
    gevent
    gunicorn
    requests
    paho-mqtt
    gntp
    cryptography
    pgpy
    smpplib
    slixmpp
    pika
    django-prometheus
    dateblock
    holidays
  ];

  passthru = {
    pythonPath = python3Packages.makePythonPath dependencies;
  };

  installPhase = ''
    mkdir -p $out/opt/apprise-api
    cp -r . $out/opt/apprise-api
    chmod +x $out/opt/apprise-api/manage.py
    makeWrapper $out/opt/apprise-api/manage.py $out/bin/apprise-api \
      --prefix PYTHONPATH : "$PYTHONPATH"
  '';

  pythonRelaxDeps = [
    # Only used for xmpp:// and holiday reminders; nixpkgs lags behind
    "slixmpp"
    "holidays"
  ];
}
