{ config, lib, pkgs, ... }:

let
  cfg = config.services.t9a-tutor;
  domain = "t9a.maurerf.com";
  port = 5179;
  # Copy of the learn-t9a content/ directory (rules/, legacy/, list/), copied by hand.
  contentDir = "/srv/t9a-tutor/content";
  stateDir = "/var/lib/t9a-tutor"; # systemd StateDirectory below
  # Root-only file with the Claude API key, passed to the service as a credential.
  apiKeyFile = "/etc/checkup-secrets/t9a-anthropic-api-key";
  proxyHeaders = ''
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    # Discard client-supplied X-Forwarded-For before the app's login rate limiter.
    proxy_set_header X-Forwarded-For $remote_addr;
    # The app sets Secure cookies from this header.
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Host $host;
    proxy_http_version 1.1;
  '';
  # The app reads ANTHROPIC_API_KEY; the key reaches the service only as a systemd credential
  # (LoadCredential fails the start if the file is missing).
  start = pkgs.writeShellScript "t9a-tutor-start" ''
    ANTHROPIC_API_KEY="$(< "$CREDENTIALS_DIRECTORY/anthropic-api-key")"
    export ANTHROPIC_API_KEY
    exec ${lib.getExe cfg.package}
  '';
in
{
  options.services.t9a-tutor = {
    enable = lib.mkEnableOption "the T9A tutor web app";

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = ''
        The app package (packages.x86_64-linux.app of the learn-t9a flake). It
        carries the code, seed data, tutor prompt and t9a-render-pages.
        Required when the service is enabled; see docs/t9a-tutor.md.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.package != null;
        message = "services.t9a-tutor.package must be set when the service is enabled (see docs/t9a-tutor.md).";
      }
    ];

    users.users.t9a-tutor = {
      isSystemUser = true;
      group = "t9a-tutor";
      home = stateDir;
    };
    users.groups.t9a-tutor = { };

    # t9a-render-pages renders the page images into the state dir (docs/t9a-tutor.md).
    environment.systemPackages = [ cfg.package ];

    # Content is private: readable only by root and the service group.
    systemd.tmpfiles.rules = [
      "d ${contentDir} 0750 root t9a-tutor -"
    ];

    systemd.services.t9a-tutor = {
      description = "T9A tutor web app";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      # Not before the content is copied: the first start seeds the database and checks its quotes against it.
      unitConfig.ConditionPathExists = "${contentDir}/rules/text";
      environment = {
        HOST = "127.0.0.1";
        PORT = toString port;
        T9A_CONTENT_DIR = contentDir;
        T9A_STATE_DIR = stateDir;
        # Claude API with a key: the Agent SDK backend needs about 395 MiB per call (docs/t9a-tutor.md).
        T9A_TUTOR_BACKEND = "api";
      };
      serviceConfig = {
        ExecStart = start;
        LoadCredential = "anthropic-api-key:${apiKeyFile}";
        User = "t9a-tutor";
        Group = "t9a-tutor";
        StateDirectory = "t9a-tutor";
        StateDirectoryMode = "0700";
        ReadOnlyPaths = [ contentDir ];
        Restart = "on-failure";
        RestartSec = "10s";
        # Packaged server peaked at about 154 MiB in a local trial (fake tutor).
        MemoryMax = "256M";
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
        UMask = "0077";
      };
      startLimitIntervalSec = 600;
      startLimitBurst = 5;
    };

    services.nginx.virtualHosts.${domain} = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString port}";
        recommendedProxySettings = false;
        extraConfig = proxyHeaders + ''
          client_max_body_size 2m;
        '';
      };
    };
  };
}
