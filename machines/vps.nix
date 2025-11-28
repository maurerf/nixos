{ ... }:

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

  # https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/issues/275
  services.dovecot2.sieve.extensions = [ "fileinto" ];
   
  # Mailserver
  mailserver = {
    enable = true;
    fqdn = "mail.maurerf.com";
    domains = [ "maurerf.com" ];

    loginAccounts = {
      "felix@maurerf.com" = {
        hashedPassword = "$2b$05$sAg0iWFwS.DKrHggtDRbre7GcEwW2mJuOAnIGpGTPdBh3wcyaVPGK";
        aliases = ["contact@maurerf.com"];
        name = "Felix Maurer";
      };
    };

    # Use Let's Encrypt certificates. Note that this needs to set up a stripped
    # down nginx and opens port 80.
    certificateScheme = "acme-nginx";
    stateVersion = 3;
  };
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "contact@maurerf.com";
}
