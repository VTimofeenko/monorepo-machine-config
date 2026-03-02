{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule {
  pname = "kroki-cli";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "yuzutech";
    repo = "kroki-cli";
    rev = "d923cdd8336257d0f19f2993c112853859f68607";
    hash = "sha256-wh/1pEmlMQNjOlCA25gq5bKEjb60Ei9JUoApsOBgSOc=";
  };

  vendorHash = "sha256-HqiNdNpNuFBfwmp2s0gsa2YVf3o0O2ILMQWfKf1Mfaw=";

  meta = {
    description = "A Kroki CLI";
    homepage = "https://github.com/yuzutech/kroki-cli";
    license = lib.licenses.mit;
    mainProgram = "kroki";
  };
}
