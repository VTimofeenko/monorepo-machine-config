My set of dotfiles and homelab configuration.

This project has been through quite a few iterations so some configs/settings may still be scattered.

# Reusable outputs

## Nvim

My neovim configuration. Contains two packages with basic nvim config and one with language servers pre-configured.

Outputs:

* `packages.[neovim|neovimWithLangs]` – runnable package with all plugins baked into it
* `nixosModules.vim` – simple module to configure neovim

## Tmux

Tmux configuration with a module and app to run it. Uses [senchopens/base16.nix](https://github.com/senchopens/base16.nix) for theming.

Outputs:

* `apps.tmux` – runnable tmux with my config
* `nixosModules.tmux` – installs tmux with custom config (wrapper around `programs.tmux.enable`)

## Zsh

Zsh configuration with all the bells and whistles.

Outputs:

* `nixosModules.zsh` – can be used to set a non-home-manager user's shell to zsh with my config
* `homeManagerModules.zsh` – can be used to set home-manager user's shell to zsh with my config
* `nixosModules.zshHMCompanionModule` – for systems where home-manager module is used, zsh would need additional files to complete e.g. systemd commands. This module fixes it.

## Hyprland helpers

A set of helpers for hyprland:


* `hyprland-lang-notifier` – shows desktop notification on language change
* `hyprland-maybe-restart-hyprland-session` – experimental helper for restarting systemd units when hyprland is quit and relaunched
* `hyprland-mode-notifier` – shows notification on hyprland mode change
* `hyprland-switch-lang-on-xremap` – changes language on xremap device; used when locking the laptop to set the language to the one the password is in.
* `hyprland-workspace-notifier` – displays a short notification every time workspace is switched

## Emacs

Contains my doom-emacs configuration. It is managed using doom emacs' own locking mechanism instead of `nix-community/nix-doom-emacs` to prevent double-building.

Also includes `kroki-cli` for rendering `org-excalidraw` diagrams.

## Theme

Contains aforementioned base16 + some semantic colors to help in styling various programs.

## Hosts blocklist

A DNS block list. This package builds a file that's included by unbound configuration.

# Repo organization

I am using two flakes: this one, public) and `data-flake` (private). Data-flake contains secrets and non-public settings. Public outputs from this flake should not depend on inputs from `data-flake` which allows reusing this flake with overriding `data-flake` to some sort of stub input.

## Passing flake outputs to itself

In this flake I am declaring some reusable modules (see `nix flake show` outoput) and using them in my configuration so I can construct one-off configurations and bring in parts of my config without too much hassle.

All NixOS and Home-manager configurations get `self.nixosModules`, `self.packages` and `self.homeManagerModules` passed as special arguments. While not very elegant (extra parameters for module configuration passed in an awkward way) it works with the way Nix modules operate. Passing them through a special option would lead to inifinite recursions.

## Flake modules
This flake takes heavy advantage of [`flake.parts`](https://flake.parts/) and, more, specifically, `flake modules`. The latter allow keeping code that produces different flake outputs together.

Case in point – [zsh config](./flake-modules/zsh/). I have three modules for zsh:

* NixOS module that can be imported on non-home-manager machines
* Home-manager module that can be used wherever home-manager is in use
* Home-manager helper NixOS module that brings in system-wide completions into the necessary scope

Rather than having three separate lines in `flake.nix` and suffer through direnv constantly rebuilding the development shell when something changes, all that's needed is:

```nix
# flake.nix
# ...
{
  outputs = inputs@{ flake-parts, ...}:
  flake-parts.lib.mkFlake {inherit inputs; }
  ({ flake-parts-lib, ... }:
  let inherit (flake-parts-lib) importApply; in
  {
    # ...
    imports = [
      (importApply ./flake-modules/zsh { inherit self; }) 
    ];
  })
}
# ...
```

And all additional modules can be imported in a similar fashion.
