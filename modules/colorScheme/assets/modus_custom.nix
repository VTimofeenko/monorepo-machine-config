# Color scheme based on Modus Vivendi Tinted
#
# base16 colors added
# The named colors ("bg-main", etc.) are taken from https://protesilaos.com/emacs/modus-themes-colors
# TODO: Base24? Maybe use https://github.com/Base24/base24-github-scheme as reference
rec {
  scheme = "modusCustom";
  # Black
  color0 = "0d0e1c";
  base00 = color0;
  color8 = "595959";
  base03 = color8;

  # red
  base01 = color1;
  color1 = red;
  base08 = color9;
  color9 = red-cooler;

  # green
  color2 = green;
  base0B = color2;
  color10 = green-warmer;

  # yellow
  color3 = yellow;
  base0A = color3;
  color11 = yellow-warmer;
  # Brown
  base0F = color11;
  # Orange
  base09 = yellow-warmer;

  # blue
  color4 = "2fafff";
  base0D = color4;
  color12 = "79a8ff";

  # magenta
  color5 = "feacd0";
  base0E = color5;
  color13 = "b6a0ff";

  # cyan
  color6 = "00d3d0";
  base0C = color6;
  color14 = "6ae4b9";

  # white
  color7 = "989898";
  base05 = color7;
  color15 = "ffffff";

  # Semantic colors
  bg-main = "000000";
  bg-dim = "1e1e1e";
  fg-main = "ffffff";
  fg-dim = "989898";
  fg-alt = "c6daff";
  bg-active = "535353";
  bg-inactive = "303030";
  border = "646464";
  red = "ff5f59";
  red-warmer = "ff6b55";
  red-cooler = "ff7f9f";
  red-faint = "ff9580";
  red-intense = "ff5f5f";
  green = "44bc44";
  green-warmer = "70b900";
  green-cooler = "00c06f";
  green-faint = "88ca9f";
  green-intense = "44df44";
  yellow = "d0bc00";
  yellow-warmer = "fec43f";
  yellow-cooler = "dfaf7a";
  yellow-faint = "d2b580";
  yellow-intense = "efef00";
  blue = "2fafff";
  blue-warmer = "79a8ff";
  blue-cooler = "00bcff";
  blue-faint = "82b0ec";
  blue-intense = "338fff";
  magenta = "feacd0";
  magenta-warmer = "f78fe7";
  magenta-cooler = "b6a0ff";
  magenta-faint = "caa6df";
  magenta-intense = "ff66ff";
  cyan = "00d3d0";
  cyan-warmer = "4ae2f0";
  cyan-cooler = "6ae4b9";
  cyan-faint = "9ac8e0";
  cyan-intense = "00eff0";
  rust = "db7b5f";
  gold = "c0965b";
  olive = "9cbd6f";
  slate = "76afbf";
  indigo = "9099d9";
  maroon = "cf7fa7";
  pink = "d09dc0";
  bg-red-intense = "9d1f1f";
  bg-green-intense = "2f822f";
  bg-yellow-intense = "7a6100";
  bg-blue-intense = "1640b0";
  bg-magenta-intense = "7030af";
  bg-cyan-intense = "2266ae";
  bg-red-subtle = "620f2a";
  bg-green-subtle = "00422a";
  bg-yellow-subtle = "4a4000";
  bg-blue-subtle = "242679";
  bg-magenta-subtle = "552f5f";
  bg-cyan-subtle = "004065";
  bg-red-nuanced = "2c0614";
  bg-green-nuanced = "001904";
  bg-yellow-nuanced = "221000";
  bg-blue-nuanced = "0f0e39";
  bg-magenta-nuanced = "230631";
  bg-cyan-nuanced = "041529";
  bg-graph-red-0 = "b52c2c";
  bg-graph-red-1 = "702020";
  bg-graph-green-0 = "4fd100";
  bg-graph-green-1 = "007800";
  bg-graph-yellow-0 = "f1e00a";
  bg-graph-yellow-1 = "b08600";
  bg-graph-blue-0 = "2fafef";
  bg-graph-blue-1 = "1f2f8f";
  bg-graph-magenta-0 = "bf94fe";
  bg-graph-magenta-1 = "5f509f";
  bg-graph-cyan-0 = "47dfea";
  bg-graph-cyan-1 = "00808f";
  bg-completion = "2f447f";
  bg-hover = "004f70";
  bg-hover-secondary = "654a39";
  bg-hl-line = "2f3849";
  bg-paren-match = "2f7f9f";
  bg-paren-expression = "453040";
  bg-region = "5c5c5c";
  bg-region-subtle = "4f1c2f";
  bg-char-0 = "0050af";
  bg-char-1 = "7f1f7f";
  bg-char-2 = "625a00";
  bg-mode-line-active = "505050";
  fg-mode-line-active = "ffffff";
  border-mode-line-active = "959595";
  bg-mode-line-inactive = "2d2d2d";
  fg-mode-line-inactive = "969696";
  border-mode-line-inactive = "606060";
  modeline-err = "ffa9bf";
  modeline-warning = "dfcf43";
  modeline-info = "9fefff";
  bg-tab-bar = "313131";
  bg-tab-current = "000000";
  bg-tab-other = "545454";
  bg-added = "00381f";
  bg-added-faint = "002910";
  bg-added-refine = "034f2f";
  bg-added-intense = "237f3f";
  fg-added = "a0e0a0";
  fg-added-intense = "80e080";
  bg-changed = "363300";
  bg-changed-faint = "2a1f00";
  bg-changed-refine = "4a4a00";
  bg-changed-intense = "8a7a00";
  fg-changed = "efef80";
  fg-changed-intense = "c0b05f";
  bg-removed = "4f1119";
  bg-removed-faint = "380a0f";
  bg-removed-refine = "781a1f";
  bg-removed-intense = "b81a1f";
  fg-removed = "ffbfbf";
  fg-removed-intense = "ff9095";
}
