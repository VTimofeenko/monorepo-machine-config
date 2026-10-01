{
  lib,
  python3Packages,
  fetchFromGitHub,
  fetchurl,
}:

let
  # mcp 2.x moved to httpx2 >= 2.5; nixpkgs has 2.3.0
  httpcore2 = python3Packages.buildPythonPackage {
    pname = "httpcore2";
    version = "2.13.1";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/09/ba/a4568248771ce81957bfb7cc600264a40fbcda092391ee1c415c50be4bea/httpcore2-2.13.1-py3-none-any.whl";
      hash = "sha256-4eBdTyX319SWv7lnSPb0tnZXsD2gabOmjDYGnz23PQo=";
    };
    dependencies = with python3Packages; [
      h11
      truststore
    ];
    doCheck = false;
  };

  httpx2 = python3Packages.buildPythonPackage {
    pname = "httpx2";
    version = "2.13.1";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/d8/9c/6fe8931fd9f381042a9e4c7d5a7b4cbf7016b252bec0c99a49fce42c3326/httpx2-2.13.1-py3-none-any.whl";
      hash = "sha256-bf9Q+rwnDuX9JdhF0LB47SBWRXl0TW2WKFCXWZbS+aQ=";
    };
    dependencies = with python3Packages; [
      anyio
      httpcore2
      idna
      truststore
      typing-extensions
    ];
    # upstream wants idna >= 3.18; nixpkgs has 3.15
    pythonRelaxDeps = [ "idna" ];
    doCheck = false;
  };

  mcp-types = python3Packages.buildPythonPackage {
    pname = "mcp_types";
    version = "2.2.0";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/8f/d7/6ffba5d8cd5dd9b8a19478875c50e04945314ba5074e84d749283f27f62d/mcp_types-2.2.0-py3-none-any.whl";
      hash = "sha256-6kdrc+6GcJq1q8lFI4XtNswFkH5YI1ViLilFlcmgTxM=";
    };
    dependencies = with python3Packages; [
      pydantic
      typing-extensions
    ];
    doCheck = false;
  };

  mcp = python3Packages.buildPythonPackage {
    pname = "mcp";
    version = "2.2.0";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/1b/ff/8e7eade68b8a28f7da0ed1085544341b51f9c935dbf6b95c76b7edfea6a0/mcp-2.2.0-py3-none-any.whl";
      hash = "sha256-vemCWJRzoGCuFF40BumlMz/lOMlyKbqEH1p/kr4AT4E=";
    };
    dependencies = [
      httpx2
      mcp-types
    ]
    ++ (with python3Packages; [
      anyio
      jsonschema
      opentelemetry-api
      pydantic
      pyjwt
      cryptography
      python-multipart
      sse-starlette
      starlette
      typing-extensions
      typing-inspection
      uvicorn
    ]);
    doCheck = false;
  };
in

python3Packages.buildPythonApplication rec {
  pname = "homebox-mcp";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "dgahagan";
    repo = "homebox-mcp";
    tag = "v${version}";
    hash = "sha256-VzUefJwTbrlwm52f1aw1q6xlbTIBVJrxDNI05QjCN0I=";
  };

  pyproject = true;
  build-system = with python3Packages; [ hatchling ];

  dependencies = [
    mcp
  ]
  ++ (with python3Packages; [
    httpx
    pillow
    pillow-heif
  ]);

  doCheck = false;

  pythonImportsCheck = [ "homebox_mcp" ];

  meta = {
    description = "MCP server for Homebox (>= 0.26): inventory Q&A, intake, attachments, labels";
    homepage = "https://github.com/dgahagan/homebox-mcp";
    license = lib.licenses.mit;
    mainProgram = "homebox-mcp";
  };
}
