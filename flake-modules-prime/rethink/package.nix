/*
  rethink: local replacement for the LG ThinQ cloud, translating appliances to
  Home Assistant MQTT.

  Docs: https://github.com/anszom/rethink/wiki
*/
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs,
  makeWrapper,
}:

buildNpmPackage (finalAttrs: {
  pname = "rethink";
  version = "0.1.4";

  src = fetchFromGitHub {
    owner = "anszom";
    repo = "rethink";
    rev = "v${finalAttrs.version}";
    hash = "sha256-j/hHVfAiyRWl9A34ueryCeeC3GBADOjHCyMIpnITZ3g=";
  };

  npmDepsHash = "sha256-eP4OVLIvCsjA4hGqwzEjpp84FdRNW80yMpR5P8YANmY=";

  nativeBuildInputs = [ makeWrapper ];

  # postinstall only installs git hooks
  npmFlags = [ "--ignore-scripts" ];

  # No .git in the source; write-version.sh takes the revision from here
  env.GIT_REVISION = "v${finalAttrs.version}";

  installPhase = ''
    runHook preInstall

    npm prune --omit=dev --ignore-scripts
    mkdir -p $out/share/rethink
    cp -r dist node_modules package.json config.jsonc $out/share/rethink/

    makeWrapper ${lib.getExe nodejs} $out/bin/rethink-cloud \
      --add-flags $out/share/rethink/dist/rethink-cloud.js
    makeWrapper ${lib.getExe nodejs} $out/bin/rethink-setup \
      --add-flags $out/share/rethink/dist/rethink-setup.js

    runHook postInstall
  '';

  meta = {
    description = "De-clouded LG ThinQ appliances, bridged to Home Assistant MQTT";
    homepage = "https://github.com/anszom/rethink";
    license = lib.licenses.gpl2Only;
    mainProgram = "rethink-cloud";
    platforms = lib.platforms.linux;
  };
})
