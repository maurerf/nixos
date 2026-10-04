{ config, lib, pkgs, ... }:

let
  bootstrapOnly = config.services.fredy.bootstrapOnly;
  proxyHeaders = ''
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    # Discard client-supplied X-Forwarded-For before Fredy's login rate limiter.
    proxy_set_header X-Forwarded-For $remote_addr;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Host $host;
    proxy_http_version 1.1;
  '';
  bootstrapGate = lib.optionalString bootstrapOnly ''
    deny all;
  '';
in
{
  options.services.fredy.bootstrapOnly = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Deny external Fredy requests until the initial admin password is changed.";
  };

  config = {
    virtualisation.podman.enable = true;
    virtualisation.oci-containers.backend = "podman";
    virtualisation.oci-containers.containers.fredy = {
      # Fredy 29.2.1, Linux amd64, GHCR index digest (2026-10-03).
      # Its /usr/bin/tini entrypoint reaps orphaned Chromium children.
      image = "ghcr.io/orangecoding/fredy@sha256:45fc1d36f8c79151f66c981c1aacde0f9d19409ffac0d9d084dcd2acecc9ea18";
      pull = "missing";
      # Keep application logs from displacing the mail journal on this small disk.
      log-driver = "k8s-file";
      ports = [ "127.0.0.1:9998:9998" ];
      volumes = [
        "/var/lib/fredy/conf:/conf"
        "/var/lib/fredy/db:/db"
      ];
      extraOptions = [
        "--memory=448m"
        "--memory-swap=576m"
        "--cpus=0.5"
        # A 29.2.1 search reached 124 PIDs; allow overlapping browser work.
        "--pids-limit=256"
        # Podman does not retain the health check in this upstream OCI image.
        "--health-cmd=curl -f http://127.0.0.1:9998/"
        "--health-interval=120s"
        "--health-timeout=10s"
        "--health-retries=3"
        "--health-start-period=60s"
        "--stop-timeout=30"
        "--security-opt=no-new-privileges"
        "--log-opt=path=/var/log/fredy/container.log"
        "--log-opt=max-size=10mb"
      ];
    };

    systemd.services.podman-fredy = {
      serviceConfig = {
        StateDirectory = "fredy";
        StateDirectoryMode = "0700";
        LogsDirectory = "fredy";
        LogsDirectoryMode = "0700";
        ExecStartPre = lib.mkBefore [
          "${pkgs.coreutils}/bin/install -d -o root -g root -m 0700 /var/lib/fredy/conf /var/lib/fredy/db"
        ];
        RestartSec = "30s";
        LogRateLimitIntervalSec = "30s";
        LogRateLimitBurst = 100;
      };
      startLimitIntervalSec = 600;
      startLimitBurst = 3;
    };

    services.nginx.virtualHosts."fredy.maurerf.com" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:9998";
        recommendedProxySettings = false;
        extraConfig = proxyHeaders + bootstrapGate;
      };
      locations."= /api/jobs/events" = {
        proxyPass = "http://127.0.0.1:9998";
        recommendedProxySettings = false;
        extraConfig = proxyHeaders + ''
          proxy_buffering off;
          proxy_read_timeout 75s;
        '' + bootstrapGate;
      };
    };
  };
}
