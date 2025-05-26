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
