/**
  Sets up starship prompt.
*/
let
  starship = {
    enable = true;
    settings = {
      # Apply the custom command instead of standard directory
      format = defaultPrompt |> builtins.replaceStrings [ "$directory" ] [ "\${custom.smart_directory} " ];
      nix_shell.symbol = " ";
      lua.symbol = " ";
      # When connected over SSH -- show the prompt with just @<hostname> instead of the globe
      hostname.format = "[@$hostname]($style)";
      # Make the hostname yellow so that it stands out
      hostname.style = "yellow";
      # Disable "in" part; I don't care for it
      username.format = "[$user]($style)";
      # # Prepend ":" to the directory
      # directory.format = ":[$path]($style)[$read_only]($read_only_style) ";

      /**
        Shows directory as ':<path>', but only if any is true:
        1. Am root
        2. Am connected through SSH

        Otherwise shows path as '<path>'
      */
      custom.smart_directory = {
        format = "[$output]($style)";
        # when = "[ \"$USER\" == \"root\" ]";
        when = "true";
        style = "bold cyan";
        command =
          # bash
          ''
            OUTPUT=""
            # If connected over SSH or am root, prepend colon
            if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] || [[ "$USER" == "root" ]]; then
              OUTPUT=":$OUTPUT"
            fi

            # Format the directory part, replacing aliases if needed
            _PWD=$(pwd)
            case $_PWD in
              "$HOME" ) DIR_OUTPUT="~";;
              * ) DIR_OUTPUT="$_PWD";;
            esac

            # Keep only last two parts of the path
            DIR_OUTPUT=$(echo -n "$DIR_OUTPUT" | rev | cut -d '/' -f-2 | rev)
            OUTPUT="$OUTPUT$DIR_OUTPUT"

            # Append space
            OUTPUT="$OUTPUT  "

            echo -n "$OUTPUT"
          '';
      };
    };
  };

  # This is starship default prompt
  defaultPrompt = ''$username$hostname$localip$shlvl$singularity$kubernetes$directory$vcsh$fossil_branch$fossil_metrics$git_branch$git_commit$git_state$git_metrics$git_status$hg_branch$pijul_channel$docker_context$package$c$cmake$cobol$daml$dart$deno$dotnet$elixir$elm$erlang$fennel$gleam$golang$guix_shell$haskell$haxe$helm$java$julia$kotlin$gradle$lua$nim$nodejs$ocaml$opa$perl$php$pulumi$purescript$python$quarto$raku$rlang$red$ruby$rust$scala$solidity$swift$terraform$typst$vlang$vagrant$zig$buf$nix_shell$conda$meson$spack$memory_usage$aws$gcloud$openstack$azure$nats$direnv$env_var$crystal$custom$sudo$cmd_duration$line_break$jobs$battery$time$status$os$container$shell$character'';
in
{
  nixosModule = {
    programs = { inherit starship; };
  };
  homeManagerModule = {
    programs = { inherit starship; };
  };
}
