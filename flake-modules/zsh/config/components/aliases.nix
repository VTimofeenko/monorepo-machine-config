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
        # Create a temporary directory and change into it
        cdtmp = "cd $(mktemp -d)";
        mkd = "mkdir -pv";
        grep = "grep --color=auto";
        mv = "mv -v";
        rm = "${pkgs.coreutils}/bin/rm -id";
        # Use fast `$CMD_EDITOR` for `vidir`
        vidir = "EDITOR=$CMD_EDITOR ${pkgs.moreutils}/bin/vidir --verbose";
        # Uses `OSC52` to copy data into the clipboard. It's up to the terminal
        # emulator to handle putting the data into the actual clipboard.
        # Alternative approach is to use `wl-copy` and `pbcopy` directly. This
        # approach does not rely on those tools, so does not bring in extra
        # dependencies where they are not needed.
        ccopy = ''
          local buffer=$(${getExe pkgs.perl} -pe 'chomp if eof' | ${pkgs.coreutils}/bin/base64 | tr -d '\n')

          if [ -n "$TMUX" ]; then
              printf "\ePtmux;\e\e]52;c;%s\a\e\\" "$buffer"
          else
              printf "\e]52;c;%s\a" "$buffer"
          fi
        '';
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
