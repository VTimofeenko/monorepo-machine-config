/**
  Spoolman 0.23.1 passes `method=` to `FileResponse`, which Starlette 1.x
  removed (HEAD is now taken from the ASGI scope). Every static frontend asset
  500s with:

  TypeError: FileResponse.__init__() got an unexpected keyword argument 'method'

  The upstream module has no `package` option, hence the overlay.

  The package serves the app from `$out/runpath`, a raw copy of `$src` made in
  `postInstall`, so `postPatch` would not reach it.
*/
{
  nixpkgs.overlays = [
    (_: prev: {
      spoolman =
        assert prev.lib.assertMsg (prev.spoolman.version == "0.23.1")
          "spoolman: check if the starlette FileResponse fix is still needed";
        prev.spoolman.overridePythonAttrs (old: {
          postInstall = (old.postInstall or "") + ''
            chmod u+w $out/runpath/spoolman $out/runpath/spoolman/client.py
            substituteInPlace $out/runpath/spoolman/client.py \
              --replace-fail ", method=method)" ")"
          '';
        });
    })
  ];
}
