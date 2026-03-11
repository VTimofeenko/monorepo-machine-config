/**
  Client(read: desktop) only settings for `broot`.
*/
{ pkgs, ... }:
{
  programs.broot = {
    settings.preview_transformers = [
      {
        input_extensions = [ "pdf" ];
        output_extension = "png";
        mode = "image";
        command = [
          "${pkgs.mupdf-headless}/bin/mutool"
          "draw"
          "-w"
          "1000"
          "-o"
          "{output-path}"
          "{input-path}"
          "1"
        ];
      }
    ];
  };

}
