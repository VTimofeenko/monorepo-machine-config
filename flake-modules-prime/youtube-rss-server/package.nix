{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "youtube-rss-server";
  version = "1.0.1";

  src = fetchFromGitHub {
    owner = "telnet23";
    repo = pname;
    tag = "v${version}";
    hash = "sha256-Xw3kw1Pw8E29592WbnSzvk2PmyE2MMtRYLTTaCOc5yw=";
  };

  vendorHash = "sha256-FCuZ+VrV1XJRT2ad69UtkoeezHtpqing5lau40DtK14=";

  env.CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
  ];

  meta = {
    description = "RSS feeds for YouTube channels and playlists backed by the YouTube Data API";
    homepage = "https://github.com/telnet23/youtube-rss-server";
    license = lib.licenses.asl20;
    mainProgram = pname;
  };
}
