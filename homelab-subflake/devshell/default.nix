# Devshell configuration for homelab-subflake
{
  commands = [
    {
      name = "validate-service";
      category = "validation";
      help = "Validate a service manifest merge (uses fzf if no argument)";
      command = builtins.readFile ./validate-service.sh;
    }
    {
      name = "validate-host";
      category = "validation";
      help = "Validate a host configuration (uses fzf if no argument)";
      command = builtins.readFile ./validate-host.sh;
    }
  ];
}
