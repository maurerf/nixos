{ pkgs, inputs, ... }:

{
  imports =
    [
      ../modules/nixos-base.nix
      ../modules/fredy.nix
      ../modules/t9a-tutor.nix
    ];

  # T9A tutor web app, see docs/t9a-tutor.md (API key and content are placed by hand first).
  services.t9a-tutor = {
    enable = true;
    package = inputs.learn-t9a.packages.${pkgs.stdenv.hostPlatform.system}.app;
  };

  networking.hostName = "nixos-vps";
  system.stateVersion = "24.05";

  # Ghostty sends TERM=xterm-ghostty over SSH; without its terminfo, zsh line
  # editing renders wrong (e.g. backspace drawn as a space).
  environment.systemPackages = [ pkgs.ghostty.terminfo ];

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
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # Keep inbound IPv6; use the correctly identified IPv4 address for outgoing mail.
  services.postfix.settings.master.smtp.args = [ "-o" "inet_protocols=ipv4" ];
  services.postfix.settings.master.relay.args = [ "-o" "inet_protocols=ipv4" ];
}
