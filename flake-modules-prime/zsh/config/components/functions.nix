{ pkgs, lib, ... }:
let
  settings.functions = {
    mkcd = {
      description = "Make a directory and change there";
      text = # bash
        ''mkdir -p "$@" && cd "$@"'';
    };

    cdd = {
      description = "cd into a file's directory";
      text = # bash
        "cd $(${dirname} $1)";
    };

    cdnixpkg = {
      description = "cd into a nix store directory where a binary is";
      text = # bash
        "cd $(${dirname} $(${readlink} --canonicalize $(which $1)))";
    };

    spacer-unbuf = {
      description = "launch command in unbuffer, piping into spacer. Preserves colors.";
      text = # bash
        ''${pkgs.expect}/bin/unbuffer "$@" | ${pkgs.lib.getExe pkgs.spacer}'';
    };

    ad-nauseam = {
      description = "Repeat last command by every press of Return";
      text = # bash
        ''while true; do read && !!; done'';
    };

    yml-to-nix = {
      description = "Turns yaml into nix to stdout.";
      text = # bash
        ''
          FROM_YML_TO_JSON_CMD="${getExe' pkgs.yq-go "yq"}"
          JSON=$($FROM_YML_TO_JSON_CMD e -o=json "$1")
          nix-instantiate --eval -E "builtins.fromJSON '''$JSON'''"
        '';
    };

    json-to-nix = {
      description = "Turns json into nix to stdout.";
      text = # bash
        ''
          nix-instantiate --eval -E "builtins.fromJSON (builtins.readFile $1)"
        '';
    };

    normalizeFileName = {
      description = "Turns an input sentence into a reasonable file name.";
      text = # bash
        ''
          echo "$1" | ${getExe' pkgs.rakudo "raku"} -e 'say $*IN.get.lc.trans(" _" => "-");'
        '';
    };

    nixBuildPackage = {
      description = "A convenience wrapper around nix-build. I can never remember this flag.";
      text = # bash
        ''
          nix-build --expr "with import <nixpkgs> {}; callPackage ./$1 {}"
        '';
    };

    _nrlf_find_flake = {
      description = "Find the nearest flake.nix by walking up from PWD to PRJ_ROOT";
      text = # bash
        ''
          local dir="$PWD"
          local root="''${PRJ_ROOT:-$PWD}"
          local git_root=""

          # Find git root
          local check_dir="$root"
          while [ "$check_dir" != "/" ]; do
            if [ -d "$check_dir/.git" ]; then
              git_root="$check_dir"
              break
            fi
            check_dir=$(dirname "$check_dir")
          done

          # Find nearest flake.nix
          while [ "$dir" != "/" ]; do
            if [ -f "$dir/flake.nix" ]; then
              if [ -n "$git_root" ]; then
                # Use git+file with ?dir= for subdirectories
                if [ "$dir" = "$git_root" ]; then
                  echo "git+file:$git_root"
                else
                  local subdir="''${dir#$git_root/}"
                  echo "git+file:$git_root?dir=$subdir"
                fi
              else
                echo "$dir"
              fi
              return
            fi

            if [ "$dir" = "$root" ]; then
              break
            fi

            dir=$(dirname "$dir")
          done

          # Fallback to root
          if [ -n "$git_root" ] && [ "$root" = "$git_root" ]; then
            echo "git+file:$root"
          else
            echo "$root"
          fi
        '';
    };
  };

  inherit (lib) getExe';
  dirname = "${pkgs.coreutils-full}/bin/dirname";
  readlink = "${pkgs.coreutils-full}/bin/readlink";

  init =
    settings.functions
    |> (builtins.mapAttrs (name: value: "${name}(){${value.text}}"))
    |> builtins.attrValues
    |> builtins.concatStringsSep "\n";
in

{
  nixosModule = {
    programs.zsh.interactiveShellInit = init;
  };
  homeManagerModule = {
    programs.zsh.initContent = init;
  };
}
