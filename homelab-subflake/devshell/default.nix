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
    {
      name = "bump-inputs";
      category = "maintenance";
      help = "Bump flake inputs with trailers (--all for all, --fixup to squash with matching previous)";
      command = builtins.readFile ./bump-inputs.sh;
    }
    {
      name = "dev-loop";
      category = "development";
      help = "Rapid iteration loop: update data-flake and deploy on each Enter press";
      command = builtins.readFile ./dev-loop.sh;
    }
    {
      name = "switch-private-inputs";
      category = "development";
      help = "Toggle data-flake and private-modules between local and remote sources";
      command = builtins.readFile ./switch-private-inputs.sh;
    }
  ];
}
