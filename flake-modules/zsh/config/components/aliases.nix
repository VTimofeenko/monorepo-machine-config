/**
  Aliases
*/
{ pkgs, lib, ... }:
let
  settings.shellAliases =
    [
      # Nix aliases
      {
        # Quick nix repl with stable nixpkgs imported
        nrn = "nix repl -f flake:ns";
        nrs = "nix repl -f flake:ns";
        # Quick nix repl with stable nixpkgs imported
        nru = "nix repl -f flake:nu";
        # Load flake into repl. Try `$PRJ_ROOT` first, if not found -- fall
        # back to `$PWD`. This is the fast way that uses git to prune unneeded
        # stuff (like `.direnv`)
        nrlf = ''nix repl --expr "builtins.getFlake \"git+file:''${PRJ_ROOT:-$PWD}\""'';
        # This is the slower way that might load extra stuff but is live
        nrrlf = ''nix repl --expr "builtins.getFlake \"''${PRJ_ROOT:-$PWD}\""'';
      }
      # ls aliases
      {
        ls = "${getExe pkgs.eza} -h --group-directories-first --icons=auto";
        l = "ls";
        ll = "ls -l";
        la = "ls -al";
      }
      # Editor
      {
        e = "$EDITOR";
        # Use vim to read the manuals
        man = "man -P 'nvim +Man!'";
        nvim = "$EDITOR";
        vim = "$EDITOR";
      }
      # Git
      {
        ga = "${getExe pkgs.git} add";
        gau = "ga -u";
        lg = "${getExe pkgs.lazygit}";
      }
      # `systemd` stuff
      {
        syu = "systemctl --user";
        ju = "journalctl --user";
      }
      # Misc
      {
        ka = "${getExe pkgs.killall}";
        cdg = "cd $(git rev-parse --show-toplevel)";
        mkd = "mkdir -pv";
        grep = "grep --color=auto";
        mv = "mv -v";
        rm = "${pkgs.coreutils}/bin/rm -id";
        # Use fast `$CMD_EDITOR` for vidir
        vidir = "EDITOR=$CMD_EDITOR ${pkgs.moreutils}/bin/vidir --verbose";
        ccopy =
          [
            "${getExe pkgs.perl} -p -e 'chomp if eof'"
            "|"
            (if pkgs.stdenv.isDarwin then "pbcopy" else "${pkgs.wl-clipboard}/bin/wl-copy")
          ]
          |> lib.concatStringsSep " ";
        # Colorize IP output
        ip = "ip -c";
        # Neat display of all relevant things in lsblk
        lsblk = "lsblk --topology --fs -o NAME,SIZE,TYPE,LABEL,UUID,FSAVAIL,FSUSE%,MOUNTPOINTS";
        # Confirm before executing things that take the node offline
        poweroff = "confirm poweroff";
        reboot = "confirm reboot";
      }
    ]
    |> lib.mergeAttrsList;

  inherit (lib) getExe;
in
{
  nixosModule = {
    programs.zsh = { inherit (settings) shellAliases; };
  };
  homeManagerModule = {
    programs.zsh = { inherit (settings) shellAliases; };
  };
}
