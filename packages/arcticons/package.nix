{
  fetchFromGitHub,
  stdenv,
  inkscape,
  scour,
  xmlstarlet,
  yq,
  jq,
}:
stdenv.mkDerivation {
  name = "Arcticons";

  srcs = [
    (fetchFromGitHub {
      owner = "Arcticons-Team";
      repo = "Arcticons";
      rev = "d1d8d5b044353725f6b0f2c80a9f64c07c3433e0";
      hash = "sha256-bkSU85JhoggFdAjakoPDNlI2j00fv2XPYIiwWrfmtXQ=";
      name = "arcticons";
    })
    (fetchFromGitHub {
      owner = "Arcticons-Team";
      repo = "Arcticons-Linux";
      rev = "953dfad6e23cbc7cce6aba2e095d0cbac17134b4";
      hash = "sha256-wJFVQS3owQFpf+zrjyrsOGQeW/uOP585U6RJEiIKtBw=";
      name = "artcicons-builder";
    })
  ];

  sourceRoot = "."; # W/a for "unpacker produced multiple directories"

  buildInputs = [
    inkscape
    scour
    xmlstarlet
    yq
    jq
  ];
  buildPhase = ''
    # Idea -- re-create the directory structure that the icons builder expect
    read -r -a sources <<< "$srcs"
    cp --recursive  "''${sources[0]}"/* .
    chmod a+w freedesktop-theme
    cd freedesktop-theme
    cp --recursive  "''${sources[1]}"/* .

    chmod --recursive a+w .
    chmod +x ./generate*.sh
    patchShebangs --build ./generate*.sh

    ./generate-all.sh
  '';

  installPhase = ''
    mkdir -p $out/share/icons
    cp -R arcticons-dark $out/share/icons
    cp -R arcticons-light $out/share/icons
  '';

  meta = {
    description = "A set of dashboard icons";
    homepage = "https://github.com/walkxcode/Dashboard-Icons";
  };
}
