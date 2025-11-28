{ config, pkgs, ... }:

{
  imports = [];

  services.openssh.enable = true;

  nix.settings.experimental-features = "nix-command flakes";

  #system.configurationRevision = self.rev or self.dirtyRev or null; # TODO: what is this?

  system.stateVersion = 4;

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  # Homebrew integration
  homebrew = {
    enable = true;
    casks = [];
    onActivation.cleanup = "none";  # Preserve existing Homebrew packages
  };
}
