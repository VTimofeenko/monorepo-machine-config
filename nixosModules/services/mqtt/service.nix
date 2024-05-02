_: {
  services.mosquitto = {
    enable = true;
    listeners = [
      {
        # TODO: implement ACLs based on something other than vpn network rules
        acl = [ "pattern readwrite #" ];
        omitPasswordAuth = true;
        settings.allow_anonymous = true;
      }
    ];
  };
}
