{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe;
  inherit (config.my-colortheme.semantic.hex) activeFrameBorder inactiveFrameBorder;
  inherit (config.my-colortheme.raw.hex) fg-main;
in
{
  programs.lazygit = {
    enable = true;
    settings = {
      gui.theme = {
        selectedLineBgColor = [ "#${inactiveFrameBorder}" ];
        selectedRangeBgColor = [ "#${inactiveFrameBorder}" ];
        activeBorderColor = [
          "#${activeFrameBorder}"
          "bold" # Otherwise strikethrough creeps in for some reason
        ];
        inactiveBorderColor = [ "#${inactiveFrameBorder}" ];
        optionsTextColor = [ "#${fg-main}" ];
      };
      git.paging.pager = "${getExe pkgs.diff-so-fancy}";
      customCommands = [
        {
          command = "git commit --message '{{.Form.Type}}{{ if .Form.Scope }}({{ .Form.Scope }}){{ end }}{{.Form.Breaking}}: {{.Form.Message}}'";
          context = "global";
          description = "Create new conventional commit";
          key = "<c-v>";
          loadingText = "Creating conventional commit...";
          prompts = [
            {
              key = "Type";
              options = [
                {
                  description = "Changes that affect the build system or external dependencies";
                  name = "build";
                  value = "build";
                }
                {
                  description = "A new feature";
                  name = "feat";
                  value = "feat";
                }
                {
                  description = "A bug fix";
                  name = "fix";
                  value = "fix";
                }
                {
                  description = "Other changes that don't modify src or test files";
                  name = "chore";
                  value = "chore";
                }
                {
                  description = "Changes to CI configuration files and scripts";
                  name = "ci";
                  value = "ci";
                }
                {
                  description = "Documentation only changes";
                  name = "docs";
                  value = "docs";
                }
                {
                  description = "A code change that improves performance";
                  name = "perf";
                  value = "perf";
                }
                {
                  description = "A code change that neither fixes a bug nor adds a feature";
                  name = "refactor";
                  value = "refactor";
                }
                {
                  description = "Reverts a previous commit";
                  name = "revert";
                  value = "revert";
                }
                {
                  description = "Changes that do not affect the meaning of the code";
                  name = "style";
                  value = "style";
                }
                {
                  description = "Adding missing tests or correcting existing tests";
                  name = "test";
                  value = "test";
                }
              ];
              title = "Type of change";
              type = "menu";
            }
            {
              initialValue = "";
              key = "Scope";
              title = "Scope";
              type = "input";
              suggestions.command = "cat .dev/scopes";
            }
            {
              key = "Breaking";
              options = [
                {
                  name = "no";
                  value = "";
                }
                {
                  name = "yes";
                  value = "!";
                }
              ];
              title = "Breaking change";
              type = "menu";
            }
            {
              initialValue = "";
              key = "Message";
              title = "message";
              type = "input";
            }
            {
              body = "Are you sure you want to commit?";
              key = "Confirm";
              title = "Commit";
              type = "confirm";
            }
          ];
        }
      ];
    };
  };
}
