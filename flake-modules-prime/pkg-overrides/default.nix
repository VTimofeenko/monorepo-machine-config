{ lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      warnIfObsolete =
        maxVersion: pkg:
        lib.warnIf (lib.versionOlder maxVersion pkg.version)
          "pkg-overrides: ${pkg.pname} override is obsolete (nixpkgs has ${pkg.version} > ${maxVersion}), consider dropping it"
          pkg;

    in
    {
      overlayAttrs = {
        centerpiece = warnIfObsolete "1.1.1" (
          pkgs.centerpiece.overrideAttrs (
            old:
            let
              newSrc = pkgs.fetchFromGitHub {
                owner = "friedow";
                repo = "centerpiece";
                rev = "cf906d878e0e46a39e338489bd06a7426c222ce2";
                hash = "sha256-9+ooog9HAUSA3mscqSSdl/LzqYLrSMZnkBnHJJUf4io=";
              };

            in
            {
              src = newSrc;
              cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
                inherit (old) pname version;
                src = newSrc;
                hash = "sha256-zGmjLmRbUqubLW4l+L4p2z8esmC/+R51KS3WFfBDFug=";
              };
            }
          )
        );
      };
    };
}
