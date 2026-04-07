{
  alertLevels = [
    "Emergency"
    "Alert"
    "Critical"
    "Error"
    "Warning"
    "Notice"
    "Informational"
    "Debug"
  ];

  severityNumMap = {
    Emergency = 21;
    Alert = 19;
    Critical = 18;
    Error = 17;
    Warning = 13;
    Notice = 10;
    Informational = 9;
    Debug = 5;
  };

  # Reverse map: _alertLevelNum (string) -> level name
  numToLevel =
    {
      "21" = "Emergency";
      "19" = "Alert";
      "18" = "Critical";
      "17" = "Error";
      "13" = "Warning";
      "10" = "Notice";
      "9" = "Informational";
      "5" = "Debug";
    };

  /**
    Produce a standard firewall rule that allows Prometheus to scrape metrics.

    TODO: allow comments
  */
  mkBackboneInnerFirewallRules =
    {
      lib,
      ports ? null,
      port ? null,
    }:
    let
      ports' =
        assert lib.assertMsg (lib.xor (isNull ports) (
          isNull port
        )) "`ports` and `port` cannot be specified together, but one of them must be specified.";
        if !isNull ports then ports else port |> lib.toList;
    in
    {
      # The validation is done by nftables, no need to make an extra check
      networking.firewall.extraInputRules =
        ports'
        # Turn into list just in case, so callers don't need to bother.
        |> lib.toList
        # Parse ports coming in as just int. If so – reconstruct attrset.
        # Otherwise leave the value be and let if fail later if needed.
        |> map (
          it:
          if lib.isInt it then
            {
              port = it;
              protocol = "tcp";
            }
          else
            it
        )
        # Construct the firewall rules
        |> map (
          it:
          [
            ''iifname "backbone-inner"''
            ''ip saddr { ${"prometheus" |> lib.homelab.getServiceInnerIP} }''
            ''${it.protocol} dport ${it.port |> toString} accept''
          ]
          |> builtins.concatStringsSep " "
        )
        |> lib.concatLines;
    };
}
