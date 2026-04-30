{
  programs.ripgrep = {
    enable = true;
    arguments = [
      "--smart-case" # lowercase = ignorecase
      "--follow" # need symlinks often
    ];
  };
}
