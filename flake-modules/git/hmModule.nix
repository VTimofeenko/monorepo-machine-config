/**
  Home manager module that configures git and related packages.
*/
{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) getExe;

  inherit (config.my-colortheme.semantic.hex) activeFrameBorder inactiveFrameBorder;
  inherit (config.my-colortheme.raw.hex) fg-main;
in
{
  home.packages = builtins.attrValues { inherit (pkgs) git git-crypt; };

  # Directory where local overrides can be places
  xdg.configFile."git/local.d/.keep".source = builtins.toFile "keep" "";
  programs = {
    git = {
      enable = true;

      aliases = {
        ci = "commit";
        st = "status";
        co = "checkout";
        rv = "remote --verbose";
        unstage = "reset HEAD --";
        # NOTE: Needs findutils xargs for -L1 argument
        pushall = "!git remote | ${pkgs.findutils}/bin/xargs -L1 git push --all";
        branch-note = "!git config branch.$(git symbolic-ref --short HEAD).note $( if [ $# -gt 0 ]; then $1; fi)";
        dft = "difftool --tool=difftastic";
      };
      userEmail = "id@vtimofeenko.com";
      userName = "Vladimir Timofeenko";
      ignores = [
        # Vim swap files
        "*.swp"
        # For Mac
        ".DS_STORE"
        # where envrc stores its stuff
        ".direnv/"
      ];
      extraConfig = {
        url."https://github.com/".insteadOf = [
          "gh:"
          "github:"
        ];
        "difftool \"difftastic\"".cmd = ''${getExe pkgs.difftastic} "$LOCAL" "$REMOTE"'';
        difftool.prompt = false; # Disables 'launch $TOOLNAME' prompt

        # Adds diffs to the commits window
        commit.verbose = true;
      };
      includes = [
        { path = "~/.config/git/local.d/gitconfig"; } # Local ad-hoc overrides for git config
      ];
    };
    gh = {
      enable = true;
      settings.prompt = "enabled";
      settings.aliases.prco = "pr checkout";
    };
    lazygit = {
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
  };
}
