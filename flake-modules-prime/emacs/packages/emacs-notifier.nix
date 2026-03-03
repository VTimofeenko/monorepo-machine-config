{
  lib,
  rustPlatform,
  pkg-config,
  stdenv,
  libiconv,
  darwin,
}:
rustPlatform.buildRustPackage {
  pname = "emacs-notifier";
  version = "0.1.0";

  src = ./emacs-notifier-src;

  cargoHash = "sha256-fLz20yrNb2yD+fngi2tUe65JEBuR4z2pu/B62aE6+eA=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = lib.optionals stdenv.isDarwin [
    libiconv
    darwin.apple_sdk.frameworks.CoreFoundation
    darwin.apple_sdk.frameworks.Cocoa
  ];

  meta = {
    mainProgram = "emacs-notifier";
  };
}
