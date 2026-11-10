My set of dotfiles and homelab configuration.

This project has been through quite a few iterations so some configs/settings may still be scattered.

# Reusable outputs

## Nvim

My neovim configuration. Contains two packages with basic nvim config and one with language servers pre-configured.

Outputs:

* `packages.[neovim|neovimWithLangs]` – runnable package with all plugins baked into it
* `nixosModules.vim` – simple module to configure neovim

## Tmux

Tmux configuration with a module and app to run it.

Outputs:

* `apps.tmux` – runnable tmux with my config
* `nixosModules.tmux` – installs tmux with custom config (wrapper around `programs.tmux.enable`)

## Zsh

Zsh configuration with all the bells and whistles.

Outputs:

* `nixosModules.zsh` – can be used to set a non-home-manager user's shell to zsh with my config
* `homeManagerModules.zsh` – can be used to set home-manager user's shell to zsh with my config
* `nixosModules.zshHMCompanionModule` – for systems where home-manager module is used, zsh would need additional files to complete e.g. systemd commands. This module fixes it.

## Emacs

Contains my doom-emacs configuration. It is managed using doom emacs' own locking mechanism instead of `nix-community/nix-doom-emacs` to prevent double-building.

## Theme

Color palette + some semantic colors to help in styling various programs.

## Hosts blocklist

A DNS block list. This package builds a file that's included by unbound configuration.

# Repo organization

This flake holds the reusable outputs (packages, NixOS/home-manager modules,
templates). Host definitions live in [`homelab-subflake`](./homelab-subflake/),
which consumes this flake as its `base` input.

## Flake modules
This flake takes heavy advantage of [`flake.parts`](https://flake.parts/) and, more, specifically, `flake modules`. The latter allow keeping code that produces different flake outputs together.

Modules live in [`flake-modules-prime`](./flake-modules-prime/) and are
picked up by [`lib/flake-module-loader.nix`](./lib/flake-module-loader.nix): a
directory either has a `default.nix` that defines its own outputs, or is built
from well-known filenames (`package.nix`, `nixos-module.nix`,
`home-manager-module.nix`, ...). Adding a module is just adding a directory.
