{ config, lib, ... }:

let
  cfg = config.services.t9a-tutor;
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
in
{
  options.services.t9a-tutor = {
    enable = lib.mkEnableOption "the T9A tutor web app";

    domain = lib.mkOption {
      type = lib.types.str;
      default = "t9a.maurerf.com";
      description = "Public host name served by nginx with ACME TLS.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 5179;
      description = "Localhost port of the Node server.";
    };

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = ''
        The app package (packages.x86_64-linux.app of the learn-t9a flake).
        Required when the service is enabled; see docs/t9a-tutor.md.
      '';
    };

    contentDir = lib.mkOption {
      type = lib.types.path;
      default = "/srv/t9a-tutor/content";
      description = ''
        Checkout of the learn-t9a repo (text/, sources/, lessons/, assets/,
        reference/, list/, app/seed/, app/prompts/). Deployed by hand, never via
        the nix store: it holds copyrighted PDFs. Created root:t9a-tutor 0750.
      '';
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/t9a-tutor";
      description = "SQLite state and backups. Must live under /var/lib (systemd StateDirectory).";
    };

    tutorBackend = lib.mkOption {
      type = lib.types.enum [ "fake" "sdk" ];
      # "fake" until the owner decides on memory: one tutor call through the
      # Claude Agent SDK peaks at about 395 MiB (node + claude), which does not
      # fit the 964 MiB VPS shared with mail and Fredy, and "sdk" also needs a
      # logged-in Claude Code on the server.
      default = "fake";
      description = "Tutor backend: canned replies (fake) or Claude Agent SDK (sdk).";
    };

    claudePath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path of the claude executable (CLAUDE_PATH); only used by the sdk backend.";
    };

    memoryMax = lib.mkOption {
      type = lib.types.str;
      default = "256M";
      description = "Hard memory cap for the server alone (fake backend). The sdk backend needs far more.";
    };

    memoryHigh = lib.mkOption {
      type = lib.types.str;
      default = "208M";
      description = "Soft memory limit (throttling) below memoryMax.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.package != null;
        message = "services.t9a-tutor.package must be set when the service is enabled (see docs/t9a-tutor.md).";
      }
      {
        assertion = lib.hasPrefix "/var/lib/" cfg.stateDir;
        message = "services.t9a-tutor.stateDir must be under /var/lib.";
      }
    ];

    users.users.t9a-tutor = {
      isSystemUser = true;
      group = "t9a-tutor";
      home = cfg.stateDir;
    };
    users.groups.t9a-tutor = { };

    # Content is private: readable only by root and the service group.
    systemd.tmpfiles.rules = [
      "d ${cfg.contentDir} 0750 root t9a-tutor -"
    ];

    systemd.services.t9a-tutor = {
      description = "T9A tutor web app";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      environment = {
        HOST = "127.0.0.1";
        PORT = toString cfg.port;
        T9A_CONTENT_DIR = toString cfg.contentDir;
        T9A_STATE_DIR = cfg.stateDir;
        T9A_TUTOR_BACKEND = cfg.tutorBackend;
      } // lib.optionalAttrs (cfg.claudePath != null) { CLAUDE_PATH = cfg.claudePath; };
      serviceConfig = {
        ExecStart = lib.getExe cfg.package;
        User = "t9a-tutor";
        Group = "t9a-tutor";
        StateDirectory = "t9a-tutor";
        StateDirectoryMode = "0700";
        ReadOnlyPaths = [ (toString cfg.contentDir) ];
        Restart = "on-failure";
        RestartSec = "10s";
        MemoryHigh = cfg.memoryHigh;
        MemoryMax = cfg.memoryMax;
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

    services.nginx.virtualHosts.${cfg.domain} = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString cfg.port}";
        recommendedProxySettings = false;
        extraConfig = proxyHeaders + ''
          client_max_body_size 2m;
        '';
      };
    };
  };
}
