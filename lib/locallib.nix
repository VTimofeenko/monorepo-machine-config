# Some helper functions that are used in this flake
{ lib, ... }:
let
  luksOpts = "noauto,nofail,_netdev";
  inherit (lib)
    pipe
    splitString
    reverseList
    concatStringsSep
    ;
in
{
  recursiveMerge =
    attrList:
    with lib;
    let
      f =
        attrPath:
        zipAttrsWith (
          n: values:
          if tail values == [ ] then
            head values
          else if all isList values then
            unique (concatLists values)
          else if all isAttrs values then
            f (attrPath ++ [ n ]) values
          else
            last values
        );
    in
    f [ ] attrList;
  # * Creates the systemd mount that waits for network to be active
  mkLuksMount =
    { device_name, target }:
    {
      what = "/dev/mapper/${device_name}";
      where = target;
      requires = [ "systemd-cryptsetup@${device_name}.service" ];
      options = luksOpts;
    };
  # * Makes a /etc/crypttab entry for a generated LUKS unit so that it's activated after SSH
  mkCryptTab =
    { device_name, UUID }:
    ''
      ${device_name} UUID=${UUID} - ${luksOpts}
    '';
  /*
    * Plucks an attribute from nested attrset, returing a list of values

       Example:
         pluck "foo" { a = { foo = 1; }; b = { bar = 2; }; c = { foo = 3; }; }
         => [ 1 3 ]
       Type:
         pluck :: String -> AttrSet -> [ Any ]
  */
  pluck =
    attrName: attrSet:
    lib.catAttrs attrName
      # Strip the outer keys and turn into a list
      (builtins.map (x: x.value) (lib.attrsets.attrsToList attrSet));

  /**
    Useful for reversing the octets of an IP address.

       Example:
         splitReverseJoin "192.168.1.2"
         => "2.1.168.192"
       Type:
         splitReverseJoin :: String -> String
  */
  splitReverseJoin =
    x:
    pipe x [
      (splitString ".")
      reverseList
      (concatStringsSep ".")
    ];
}
