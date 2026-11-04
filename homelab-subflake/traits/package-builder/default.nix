/**
  Lets this host's nix-daemon fetch package sources from Gitea behind
  REQUIRE_SIGNIN_VIEW (e.g. `fetchFromGitea`).

  - nixpkgs' fetchurl appends `$NIX_CURL_FLAGS` to curl and passes it through
    as an impure env var, so fixed-output builds pick it up from the daemon.
  - the netrc is bind-mounted into the build sandbox; builders run as nixbld,
    hence the group ownership on the secret
  - `netrc-file` covers Nix's own downloader (substituters, `builtins.fetchTarball`,
    tarball flake inputs)
*/
{ config, ... }:
let
  netrcPath = config.age.secrets.gitea-netrc.path;
in
{
  nix.settings = {
    netrc-file = netrcPath;
    extra-sandbox-paths = [ netrcPath ];
  };
  systemd.services.nix-daemon.environment.NIX_CURL_FLAGS = "--netrc-file ${netrcPath}";
}
