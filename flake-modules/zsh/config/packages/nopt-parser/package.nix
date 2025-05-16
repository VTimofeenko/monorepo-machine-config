{
  python3Packages,
}:
python3Packages.buildPythonApplication {
  pname = "nopt-parser";
  version = "0.1.0";
  src = ./nopt-parser;
  pyproject = true;

  build-system = [ python3Packages.setuptools ];

  dependencies = [
    python3Packages.click
    python3Packages.rich
    python3Packages.toolz
  ];
}
