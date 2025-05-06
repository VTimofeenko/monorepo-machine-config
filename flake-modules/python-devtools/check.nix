{ self, ... }:
{ pkgs, ... }:
{
  test-python-formatter = pkgs.testers.runNixOSTest {
    name = "check-python-formatter";

    nodes.machine =
      { pkgs, ... }:
      {
        environment.systemPackages = [ self.packages.${pkgs.system}.python-formatter ];
      };

    testScript =
      # python
      ''
        print("AAA")
        file = "/tmp/test.py"
        docstring = "docstring"

        machine.execute(f"echo \"'{docstring}'\" > {file}")
        machine.execute(f"i-dont-care-just-format-my-python-code-and-yell-at-me {file}")

        result = machine.execute(f"cat {file}")
        assert result[1] == f"\"\"\"{docstring}\"\"\"\n", f"Something went wrong, got: {result} after ruff fix"
      '';
  };
}
