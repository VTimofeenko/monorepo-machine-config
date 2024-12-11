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
      # Doc:
      # https://github.com/jesseduffield/lazygit/blob/master/docs/Custom_Command_Keybindings.md
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
              command = lib.pipe ./conventional-commit-helper [
                (lib.flip pkgs.callPackage { })
                lib.getExe
              ];
              filter = "((?P<c_type>[a-z]*):.*)";
              valueFormat = "{{ .c_type }}";
              labelFormat = "{{ .group_1 }}";
              title = "Type of change";
              type = "menuFromCommand";
            }
            {
              initialValue = "";
              key = "Scope";
              title = "Scope";
              type = "input";
              suggestions.command = "cat .dev/scopes";
            }
            # Breaking changes are rare -- I'd rather use reword for them
            # {
            #   key = "Breaking";
            #   options = [
            #     {
            #       name = "no";
            #       value = "";
            #     }
            #     {
            #       name = "yes";
            #       value = "!";
            #     }
            #   ];
            #   title = "Breaking change";
            #   type = "menu";
            # }
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
