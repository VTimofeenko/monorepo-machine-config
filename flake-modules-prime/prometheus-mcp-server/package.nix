{
  lib,
  python3Packages,
  fetchFromGitHub,
  fetchPypi,
  fetchurl,
}:

let
  pyproject-toml = python3Packages.buildPythonPackage {
    pname = "pyproject_toml";
    version = "0.1.0";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/38/c1/d8dd436dc2c2e323441b98abf7bee8c51bda5ca6d066ec46d8163a1aeaa9/pyproject_toml-0.1.0-py3-none-any.whl";
      hash = "sha256-lr+NRxYtXK5Bfn20bn8fUa+RW8zmIDUOLPrj4keOMBs=";
    };
    dependencies = with python3Packages; [
      packaging
      pydantic
      setuptools
    ];
    doCheck = false;
  };

  uncalled-for = python3Packages.buildPythonPackage rec {
    pname = "uncalled_for";
    version = "0.2.0";
    pyproject = true;
    src = fetchPypi {
      inherit pname version;
      hash = "sha256-tPj9vOwyjFoROAfWU+BBxQlEc91K+nw0WZrOacy35p8=";
    };
    build-system = with python3Packages; [
      hatchling
      hatch-vcs
    ];
    doCheck = false;
  };

  py-key-value-aio = python3Packages.buildPythonPackage {
    pname = "py_key_value_aio";
    version = "0.4.4";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/32/69/f1b537ee70b7def42d63124a539ed3026a11a3ffc3086947a1ca6e861868/py_key_value_aio-0.4.4-py3-none-any.whl";
      hash = "sha256-GOF1ZOyuYbmH+Qn8LNQe4gEshLSx3LjAVc+LS8G/P10=";
    };
    dependencies = with python3Packages; [
      beartype
      typing-extensions
      # extras: `filetree`, `keyring`, `memory` (all required by `fastmcp`)
      aiofile
      anyio
      keyring
      cachetools
    ];
    doCheck = false;
  };

  mcp = python3Packages.mcp.overridePythonAttrs (_: {
    version = "1.26.0";
    pyproject = null;
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/fd/d9/eaa1f80170d2b7c5ba23f3b59f766f3a0bb41155fbc32a69adfa1adaaef9/mcp-1.26.0-py3-none-any.whl";
      hash = "sha256-kEohwzwlqpjdvrRycwM8Q15ZW7rP2xd/S9h/bc7r4co=";
    };
    dependencies = with python3Packages; [
      anyio
      httpx
      httpx-sse
      jsonschema
      pydantic
      pydantic-settings
      pyjwt
      python-multipart
      sse-starlette
      starlette
      typing-extensions
      uvicorn
      # cli extras
      python-dotenv
      typer
    ];
    doCheck = false;
  });

  fastmcp =
    python3Packages.fastmcp.overridePythonAttrs (_: {
      version = "3.2.0";
      src = fetchPypi {
        pname = "fastmcp";
        version = "3.2.0";
        hash = "sha256-1IMLj/w1ktPZx23A85iQTPQfBJEOQaDeOMwQBOCQO+8=";
      };
      doCheck = false;
    })
    |> (
      p:
      p.overrideAttrs (old: {
        # Replace propagatedBuildInputs wholesale — fastmcp 3.2.0 has different deps
        # from 2.14.5 in nixpkgs (notably: no pydocket, diskcache, keyring, etc.;
        # new: uncalled-for, py-key-value-aio 0.4.4, watchfiles).
        propagatedBuildInputs = with python3Packages; [
          authlib
          cyclopts
          httpx
          jsonref
          jsonschema-path
          openapi-pydantic
          opentelemetry-api
          packaging
          platformdirs
          pydantic
          pyperclip
          python-dotenv
          pyyaml
          rich
          uvicorn
          watchfiles
          websockets
          uncalled-for
          py-key-value-aio
          mcp
        ];
        nativeBuildInputs =
          (old.nativeBuildInputs or [ ])
          |> builtins.filter (dep: dep.name or "" != "python-runtime-deps-check-hook.sh");
      })
    );
in

python3Packages.buildPythonApplication rec {
  pname = "prometheus-mcp-server";
  version = "1.6.0";

  src = fetchFromGitHub {
    owner = "pab1it0";
    repo = "prometheus-mcp-server";
    tag = "v${version}";
    hash = "sha256-8MusCGOLHp0wXEgBeXLRIOUjptaVqTK21Ns+okYB4Bo=";
  };

  pyproject = true;
  build-system = with python3Packages; [ setuptools ];

  dependencies = [
    fastmcp
    mcp
  ]
  ++ (with python3Packages; [
    prometheus-api-client
    pyproject-toml
    python-dotenv
    requests
    structlog
  ]);

  doCheck = false;

  meta = {
    description = "MCP server for Prometheus integration";
    homepage = "https://github.com/pab1it0/prometheus-mcp-server";
    license = lib.licenses.mit;
    mainProgram = "prometheus-mcp-server";
  };
}
