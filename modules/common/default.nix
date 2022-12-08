{ ... }:
{
  imports = [
    ./flakes.nix
    ./fonts.nix
    ./user.nix
    ./utils.nix
    ./zsh.nix
  ];
  time.timeZone = "America/Los_Angeles";
  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  # Allow unfree packages across the board
  nixpkgs.config.allowUnfree = true;
}
