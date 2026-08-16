/**
  Enables `xdg.mimeApps`. The actual mimetype -> app associations are
  contributed by whichever trait installs the app in question (e.g.
  `user-editors`, `user-document-viewers`, `user-media`, `user-browser`),
  and merge into this via the NixOS/home-manager module system.
*/
{
  xdg.mimeApps.enable = true;
}
