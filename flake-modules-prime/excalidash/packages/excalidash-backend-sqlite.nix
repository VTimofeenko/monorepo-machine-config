/**
  ExcaliDash backend, built with Prisma's `sqlite` provider instead of
  `postgresql` — see ./excalidash-backend.nix (the `databaseProvider`
  parameter there) for what this actually changes.
*/
{ callPackage }:
callPackage ./excalidash-backend.nix { databaseProvider = "sqlite"; }
