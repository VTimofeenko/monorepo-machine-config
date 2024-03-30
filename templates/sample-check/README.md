This is a sample flake that allows hte user to run an interactive nixos test. It can be expanded to test arbitrary modules/packages

# How to use this
1. `nix build -L .\#checks.x86_64-linux.test.driverInteractive` (or just `nix run ...` and skip step 2.)
2. `./result/bin/nixos-test-driver`
3. `start_all()`
