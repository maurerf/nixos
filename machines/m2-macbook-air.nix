{ config, pkgs, ... }:

{
  imports = [];

  services.openssh.enable = true;

  networking.networkmanager.enable = true;
  networking.hostName = "m2-macbook-air";

  nix.settings.experimental-features = "nix-command flakes";

  system.configurationRevision = self.rev or self.dirtyRev or null;

  system.stateVersion = "23.05";

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;
}
