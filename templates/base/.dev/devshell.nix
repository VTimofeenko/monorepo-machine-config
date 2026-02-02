{ pkgs, ... }:
{
  default = {
    env = [
      {
        name = "HTTP_PORT";
        value = 8080;
      }
    ];
    commands = [
      {
        help = "print hello";
        name = "hello";
        command = "echo hello";
      }
    ];
    packages = [
      pkgs.cowsay
    ];
  };
}
