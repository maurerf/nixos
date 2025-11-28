{ config, pkgs, ... }:

{
  imports = [];

  services.openssh.enable = true;

  nix.settings.experimental-features = "nix-command flakes";

  #system.configurationRevision = self.rev or self.dirtyRev or null; # TODO: what is this?

  system.stateVersion = 4;

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  # User configuration
  users.users.fdm = {
    name = "fdm";
    home = "/Users/fdm";
  };

  # Homebrew integration
  homebrew = {
    enable = true;
    casks = [
      "rar"      # Proprietary, not available in nixpkgs
      "steam"    # Better macOS integration via Homebrew
      "openscad" # Build issues with Qt5 dependencies in nixpkgs-unstable
    ];
    onActivation.cleanup = "none";  # Preserve existing Homebrew packages
  };
}
