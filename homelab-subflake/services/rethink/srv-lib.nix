_: {
  /**
    LG appliances (host names) that are redirected to rethink: their DNS
    view sends `*.lgthinq.com` here and the firewall lets them reach :443
    and :8883.
  */
  appliances = [
    "oven"
    "washer"
    "dryer"
  ];
}
