#!/usr/bin/env bash
# Run on the VPS yourself. Writes no report file and makes no configuration changes.
# Run as your normal login user; privileged reads use sudo -n and may fail.
# Inspect output for private operational metadata before sharing. No secret files,
# service environments, logs, process arguments, or backup repository contents are read.
set -u
export SYSTEMD_PAGER=cat PAGER=cat
run() {
  printf '\n$'; printf ' %q' "$@"; printf '\n'
  "$@" 2>&1
  printf '[exit %s]\n' "$?"
}
run date -u
run hostname
run uname -m
run nix --version
run nixos-version --json
run nixos-version --configuration-revision
run readlink -f /run/current-system
run readlink -f /nix/var/nix/profiles/system
run bash -c 'for p in /nix/var/nix/profiles/system-*-link; do [ -L "$p" ] || continue; stat -c "%n %y" "$p"; readlink "$p"; done'
run nix-channel --list
run sudo -n nix-channel --list
run bash -c 'for p in /etc/nixos/flake.nix /etc/nixos/flake.lock /etc/nixos/configuration.nix /etc/nix/nix.conf /etc/nixos/.git /run/current-system/configuration.nix; do if [ -e "$p" ]; then ls -ld "$p"; fi; done'
run systemctl is-active nix-daemon.service
run systemctl --failed --no-pager --plain
run df -h / /nix/store
run sudo -n du -sh /nix/store
run uptime
run uptime -s
run who -b
run last -x reboot -n 3
run systemctl list-unit-files --state=enabled --type=service --no-pager
run systemctl list-units --state=running --type=service --no-pager
run ss -lntu
run systemctl show firewall.service --property=LoadState,ActiveState,SubState,Result
run sudo -n nft list ruleset
run sudo -n iptables -S
run sudo -n ip6tables -S
run systemctl list-timers --all --no-pager
printf '\n$ backup unit status (selected metadata only)\n'
while read -r unit rest; do
  case "$unit" in
    *borg*|*restic*|*backup*|*snapshot*)
      run systemctl show "$unit" --property=Id,LoadState,ActiveState,SubState,Result,ExecMainCode,ExecMainStatus,ExecMainExitTimestamp,LastTriggerUSec,NextElapseUSecRealtime
      ;;
  esac
done < <(systemctl list-unit-files --type=service --type=timer --no-legend --no-pager)
printf '\nBackup jobs do not prove recoverability. Separately report provider backups, protected data, latest successful backup and restore test, retention, downtime allowance, and console access. Do not paste credentials.\n'
