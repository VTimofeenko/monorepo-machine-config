# Some helper functions that are used in this flake
{ lib, ... }:
let
  luksOpts = "noauto,nofail,_netdev";
in
{
  recursiveMerge = attrList:
    with lib;
    let
      f = attrPath:
        zipAttrsWith (n: values:
          if tail values == [ ]
          then head values
          else if all isList values
          then unique (concatLists values)
          else if all isAttrs values
          then f (attrPath ++ [ n ]) values
          else last values
        );
    in
    f [ ] attrList;
  /** Creates the systemd mount that waits for network to be active */
  mkLuksMount =
    { device_name, target }:
    {
      what = "/dev/mapper/${device_name}";
      where = "/var/lib/${target}";
      requires = [ "systemd-cryptsetup@${device_name}.service" ];
      options = luksOpts;
    };
  /** Makes a /etc/crypttab entry for a generated LUKS unit so that it's activated after SSH */
  mkCryptTab =
    { device_name, UUID }:
    ''
      ${device_name} UUID=${UUID} - ${luksOpts}
    '';
}
