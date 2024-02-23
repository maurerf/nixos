{ config, pkgs, inputs, ... }:

{
  imports =
    [
      ./minimal.nix
    ];

  # Bootloader
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  #boot.loader.grub.efiSupport = true;
  #boot.loader.grub.useOSProber = true;
   
  # Mailserver
  mailserver = {
    enable = true;
    fqdn = "mail.maurerf.com";
    domains = [ "maurerf.com" ];

    loginAccounts = {
      "felix@maurerf.com" = {
        hashedPasswordFile = "/etc/nixos/hosts/vps/mailserver-pw-hashes/felix.txt";
        aliases = ["contact@maurerf.com"];
	      name = "Felix Maurer";
      };
    };

    # Use Let's Encrypt certificates. Note that this needs to set up a stripped
    # down nginx and opens port 80.
    certificateScheme = "acme-nginx";
  };
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "contact@maurerf.com";
}
