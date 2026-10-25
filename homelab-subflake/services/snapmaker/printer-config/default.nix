/**
  Printer-side configuration, as `<path in Moonraker "config" root> = <content>`.

  Pushed by `snapmaker-push`. Moonraker includes managed here are prefixed
  with `managedPrefix`; stale ones with that prefix get removed on push.
*/
{ lib, relayHostIP }:
let
  inherit (lib.homelab) getServiceFqdn;

  # Moonraker/Klipper INI flavor: `key: value`, lists as indented lines
  toCfg = lib.generators.toINI {
    mkKeyValue =
      k: v:
      let
        mkValue = it: if lib.isBool it then lib.boolToString it else toString it;
      in
      if lib.isList v then
        "${k}:" + lib.concatMapStrings (it: "\n    ${mkValue it}") v
      else
        "${k}: ${mkValue v}";
  };

  # Printer ships Apprise 2.x which defaults to sending the key in a header
  # (`version=2`); apprise-api 1.x only reads it from the path.
  # Fetched by Moonraker on the printer itself, forwarded as an attachment
  snapshot = "http://127.0.0.1/webcam/snapshot.jpg";

  fluiddUrl = "https://${getServiceFqdn "snapmaker"}";

  appriseUrl = key: "apprises://${getServiceFqdn "apprise"}/${key}?version=1";
  managedPrefix = "extended/moonraker/50-nix-";
in
{
  inherit managedPrefix;

  files = {
    # Full replacement of the firmware's file. Options not listed here use the
    # firmware defaults. Changing this file requires a reboot.
    "extended/extended2.cfg" = toCfg {
      web = {
        frontend = "fluidd";
        firmware_config = true;
        remote_screen = false;
      };
      camera = {
        internal = "paxx12";
        usb = "none";
        rtsp = false;
      };
      remote_access = {
        ssh = true;
        vpn = "none";
        cloud = "none";
      };
      monitoring.klipper_exporter = ":9101";
      spoolman = {
        host = "https://${getServiceFqdn "spoolman"}";
        force_generic_vendor = false;
      };
    };

    # Overrides the stock [authorization] which trusts all private ranges.
    # Everything non-local goes through the relay host.
    "${managedPrefix}authorization.cfg" = toCfg {
      authorization = {
        trusted_clients = [
          "127.0.0.0/8"
          "::1/128"
          "${relayHostIP}/32"
        ];
        cors_domains = [
          "*://localhost"
          "*://localhost:*"
          "https://${getServiceFqdn "snapmaker"}"
        ];
      };
    };

    # Overrides the firmware's WebRTC default: WebRTC media goes over UDP
    # directly to the printer, which only the relay host can reach. The
    # player fetches H.264 over plain HTTP, so it works through the proxy.
    "${managedPrefix}webcam.cfg" = toCfg {
      "webcam case" = {
        service = "iframe";
        stream_url = "/webcam/player";
        target_fps = 15;
      };
    };

    "${managedPrefix}notifier.cfg" = toCfg {
      "notifier print_complete" = {
        url = appriseUrl "ntfy-fyi-default";
        attach = snapshot;
        events = "complete";
        title = "Snapmaker U1";
        body = "Finished {event_args[1].filename} ${fluiddUrl}";
      };
      "notifier print_attention" = {
        url = appriseUrl "ntfy-fyi-high";
        attach = snapshot;
        events = "error, paused";
        title = "Snapmaker U1 needs attention";
        body = "{event_args[1].filename}: {event_name} {event_args[1].message} ${fluiddUrl}";
      };
    };
  };
}
