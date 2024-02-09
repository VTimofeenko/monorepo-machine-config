# NixOS module that sets up tiny tiny rss
_: {
  imports = [
    ./tt-rss.nix
    ./ssl.nix
  ];
}
