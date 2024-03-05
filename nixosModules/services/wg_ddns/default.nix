# This module configures dynamic DNS for client network entrypoint
{ ... }:
{
  imports = [ ./cloudflare-dyndns.nix ];
}
