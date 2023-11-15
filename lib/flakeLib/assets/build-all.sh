#!/usr/bin/env bash

# Turns the system string into system format that Nix needs
# x86_64 on Linux becomes "x86_64-Linux"
# M1 Mac becomes "aarch64-darwin"
# This var is cast to lower later
NIX_SYSTEM="$(uname -m| sed 's;arm;aarch;')-$(uname -o | sed 's;GNU/;;')"


# nix flake show will look up for a flake.nix file
for pkg in $(nix flake show \
    --json `# parse later using jq` \
    2>/dev/null `# discard warnings` \
    | jq ".packages.\"${NIX_SYSTEM,,}\" | keys[]");
do
    nix build .#"${pkg}"
done
