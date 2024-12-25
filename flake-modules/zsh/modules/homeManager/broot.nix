{ pkgs, lib, ... }:
{
  programs.broot = {
    enable = true;
    settings = {
      modal = true;
      default_flags = "--sort-by-type-dirs-last";
      preview_transformers = [
        {
          input_extensions = [ "json" ];
          output_extension = "json";
          mode = "text";
          command = [
            lib.getExe
            pkgs.jq
          ];
        }
      ];
    };
  };
}
