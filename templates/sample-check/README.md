This is a sample flake that allows the user to run an interactive NixOS test. It
can be expanded to test arbitrary modules/packages

# How to use

1. `nix flake init -t github:VTimofeenko/monorepo-machine-config#sample-check`
2. Edit the `flake.nix` to include configuration you want to test
3. `nix build -L .\#checks.x86_64-linux.test.driverInteractive` (or just `nix run ...` and skip next step)
4. `./result/bin/nixos-test-driver`
5. `start_all()`
