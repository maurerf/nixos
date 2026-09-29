{ ... }:

{
  imports =
    [
      ../modules/nixos-base.nix
    ];

  networking.hostName = "nixos-vps";

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  #boot.loader.grub.efiSupport = true;
  #boot.loader.grub.useOSProber = true;

  # Mailserver
  mailserver = {
    enable = true;
    fqdn = "mail.maurerf.com";
    domains = [ "maurerf.com" ];

    accounts = {
      "felix@maurerf.com" = {
        hashedPasswordFile = "/etc/checkup-secrets/mail-felix.hash";
        aliases = ["contact@maurerf.com"];
        name = "Felix Maurer";
      };
    };

    # Reuse the existing ACME host name; nginx serves the HTTP-01 challenge.
    x509.useACMEHost = "mail.maurerf.com";
    stateVersion = 3;
  };
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "contact@maurerf.com";
  services.nginx = {
    enable = true;
    virtualHosts."mail.maurerf.com".enableACME = true;
  };
  networking.firewall.allowedTCPPorts = [ 80 ];

  # Keep inbound IPv6; use the correctly identified IPv4 address for outgoing mail.
  services.postfix.settings.master.smtp.args = [ "-o" "inet_protocols=ipv4" ];
  services.postfix.settings.master.relay.args = [ "-o" "inet_protocols=ipv4" ];
}
