/**
  Allows users to work on
  - automations
  - scripts
  - scenes

  in HA UI while keeping the nix-managed stuff declarative.

  This file was stole^W inspired by https://wiki.nixos.org/wiki/Home_Assistant
*/
{ config, lib, ... }:
let
  # WARN: relies on default home assistant file names
  uiEditableConfigCategories = [
    "automations"
    "scenes"
    "scripts"
  ];
  inherit (lib) pipe;
in
{
  services.home-assistant.config = pipe uiEditableConfigCategories [
    (map (cat: {
      name = "${cat} ui";
      value = "!include ${cat}.yaml";
    }))
    builtins.listToAttrs
  ];

  # Otherwise HA might complain about missing file
  systemd.tmpfiles.rules = map (
    cat:
    (lib.concatStringsSep " " [
      "f"
      "${config.services.home-assistant.configDir}/${cat}.yaml"
      "0755"
      "${config.systemd.services.home-assistant.serviceConfig.User}"
      "${config.systemd.services.home-assistant.serviceConfig.Group}"
    ])
  ) uiEditableConfigCategories;
}
