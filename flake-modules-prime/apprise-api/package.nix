/**
  `apprise-api` python package.

  Package is modeled after `netbox` since they are both Django apps
*/

{
  python3Packages,
  fetchFromGitHub,
}:

python3Packages.buildPythonApplication rec {
  pname = "apprise-api";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "caronc";
    repo = "apprise-api";
    tag = "v${version}";
    hash = "sha256-tFhlBKRliGyx0t2k/81Q8igdyIpMKagkTKgTXk+9tus=";
  };

  pyproject = true;
  build-system = with python3Packages; [
    setuptools
  ];

  dependencies = with python3Packages; [
    (apprise.overridePythonAttrs (old: rec {
      version = "1.9.6";
      src = fetchPypi {
        pname = "apprise";
        inherit version;
        hash = "sha256-Qga+nLVpSj0I3Y4Dk7u5s2ISrDp3acJjNiAFXnXGyu8=";
      };
      doCheck = false; # YOLO
    }))
    django
    gevent
    gunicorn
    requests
    paho-mqtt
    gntp
    cryptography
    django-prometheus
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
    "paho-mqtt" # Needs 2.0, have 2.1
  ];
}
