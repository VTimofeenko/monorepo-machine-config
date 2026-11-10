My dotfiles and homelab configuration, as two flakes:

- **This flake** produces the reusable outputs: packages, NixOS and
  home-manager modules, and project templates. See `nix flake show` for the
  current list or check the contents of the flake modules directory.
- **[`homelab-subflake`](./homelab-subflake/)** holds the host definitions and
  homelab services. It takes this flake as its `base` input. Its
  [README](./homelab-subflake/README.md) covers the architecture.

# Repo organization

| Path | What's there |
|---|---|
| [`flake-modules-prime/`](./flake-modules-prime/) | One directory per module, producing most of this flake's outputs |
| [`lib/`](./lib/) | The module loader and the devshell commands |
| [`templates/`](./templates/) | `nix flake init -t` templates |

## Flake modules

[`lib/flake-module-loader.nix`](./lib/flake-module-loader.nix) imports every
directory in `flake-modules-prime/` as a [flake-parts](https://flake.parts/)
module. A directory either has a `default.nix` that defines its own outputs, or
is assembled from well-known filenames:

| File | Output |
|---|---|
| `package.nix`, `packages/*.nix` | `packages.<name>` (also added to `overlays.default`) |
| `app.nix`, `apps/*.nix` | `apps.<name>` |
| `check.nix`, `checks/*.nix` | `checks.<name>` |
| `nixos-module.nix`, `nixos-modules/*.nix` | `nixosModules.<name>` |
| `home-manager-module.nix`, `home-manager-modules/*.nix` | `homeManagerModules.<name>` |
