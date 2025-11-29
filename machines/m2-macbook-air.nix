{ config, pkgs, ... }:

{
  imports = [
    # Note: modules/nixos-base.nix is Linux-specific, so we don't import it for Darwin
  ];

  services.openssh.enable = true;

  nix.settings.experimental-features = "nix-command flakes";
  nix.channel.enable = false;

  # Nix-darwin stateVersion - represents the nix-darwin release version when this config was first created
  # This helps maintain backwards compatibility during system upgrades
  system.stateVersion = 5;

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  users.users.fdm = {
    name = "fdm";
    home = "/Users/fdm";
  };
  
  system.primaryUser = "fdm";
  # Homebrew as backup utility - minimal integration to avoid changes during activation
  homebrew = {
    enable = true;
    # No packages managed by nix-darwin - use Homebrew manually when needed
    brews = [];
    casks = [];
    onActivation = {
      cleanup = "none";        # Never cleanup nix-darwin managed packages (preserves manual installs)
      upgrade = false;         # Sets HOMEBREW_BUNDLE_NO_UPGRADE=1 (same effect as --no-upgrade)
      autoUpdate = false;      # Prevents Homebrew itself from auto-updating during activation
    };
  };
}
