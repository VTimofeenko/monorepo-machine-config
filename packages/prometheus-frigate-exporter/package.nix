{
  python3,
  lib,
  fetchFromGitHub,
}:

python3.pkgs.buildPythonApplication rec {
  pname = "prometheus-frigate-exporter";
  version = "v0.1.1-git";
  format = "other";

  src = fetchFromGitHub {
    owner = "bairhys";
    repo = pname;
    hash = "sha256-yhKBpTURhO8yboOeDZ1Y1VLI1xJLi5UmNA8GCvWADTc=";
    rev = "8a5b45c3f853f1ce537c99e773baef629a2d68dd";
  };

  propagatedBuildInputs = with python3.pkgs; [
    prometheus-client
  ];
  installPhase = ''
    mkdir -p $out/bin
    echo "#!/usr/bin/env python3" > $out/bin/prometheus-frigate-exporter
    cat $src/prometheus_frigate_exporter.py >> $out/bin/prometheus-frigate-exporter
    chmod +x $out/bin/prometheus-frigate-exporter
  '';
  dontBuild = true;
  dontConfigure = true;

  meta = {
    description = "Prometheus frigate metrics exporter";
    homepage = "https://github.com/bairhys/prometheus-frigate-exporter";
    license = lib.licenses.mit;
    # maintainers = [];
  };
}
