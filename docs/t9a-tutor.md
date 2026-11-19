# T9A tutor web app on the VPS

[Knowledge index](README.md) · [Deployment](deployment.md) · [VPS recovery](vps-recovery.md)

Self-hosted web app from the private repo `maurerf/learn-t9a`: one Node process on
`127.0.0.1:5179` behind nginx at `https://t9a.maurerf.com`, SQLite state, its own
password login. [`modules/t9a-tutor.nix`](../modules/t9a-tutor.nix) declares the
service (paths, port and host name fixed there); [`machines/vps.nix`](../machines/vps.nix) enables it with the package from
the `learn-t9a` flake input. Activation needs the [deployment approval](deployment.md#deployment).

The tutor uses the Claude API (`tutorBackend = "api"`, billed per token from prepaid
credits, spend limit set in the Claude Console). The Agent SDK backend (about 395 MiB
per call and a logged-in Claude Code) does not fit this VPS. The packaged server
peaked at about 154 MiB in a local trial with the fake tutor; `MemoryMax` is 256M.
Confirm the peak with real tutor calls after activation (`systemctl status t9a-tutor`).

## Source of the package

`learn-t9a` is private. The flake input is `git+https`, locked on a machine whose git
reads the repo with the operator's normal GitHub login. The VPS holds no GitHub
credential: before each VPS rebuild, copy the locked flake and all its inputs into the
VPS store from a machine with both the GitHub login and VPS SSH access (the Mac, or
desktop-pc with its VPS key; `maurerf.com` and `mail.maurerf.com` share one host key):

```sh
nix flake archive --to ssh://maurerf.com "github:maurerf/nixos/$CANDIDATE"
# desktop-pc:
nix flake archive --to 'ssh://fdm@mail.maurerf.com?ssh-key=/home/fdm/.ssh/id_ed25519_vps' "github:maurerf/nixos/$CANDIDATE"
```

`nixos-rebuild` on the VPS then finds the locked `learn-t9a` source in its store and
does not fetch it. The source tree includes the copyrighted rules files, so they
are in the VPS store too; accepted in [decisions](decisions.md) (single-user VPS).
The copy is accepted for the non-trusted SSH user `fdm` (source paths are
content-addressed), and the VPS then evaluates the candidate without reaching the repo
(both checked for `564838c` on 2026-11-19). If that ever fails, stop and decide; do not
add `fdm` to `trusted-users` or put a token on the VPS without a recorded decision.

CI cannot fetch the repo either: it overrides the input with the stub in
[`ci/learn-t9a-stub`](../ci/learn-t9a-stub/flake.nix), so a green CI run says nothing
about the app itself. Before activation, build the candidate's `vps` system locally
with the real input.

## One-time setup

1. DNS: `A`/`AAAA` record `t9a.maurerf.com` to the VPS (as for Fredy). Ports 80 and
   443 are already open for Fredy; recheck the Vultr firewall.
2. API key (before activation): create it in the Claude Console ("Somewhere else",
   name `t9a-vps`). Write it privately, without echo or shell history, as a root-only
   file; systemd passes it to the service as the credential `anthropic-api-key`
   (`LoadCredential`), so it never enters the nix store or a unit file:
   ```sh
   sudo sh -c 'umask 077; set -C; printf "API key: " >&2; read -rs k && printf %s "$k" > /etc/checkup-secrets/t9a-anthropic-api-key; echo >&2'
   sudo stat -c '%U:%G %a %s %n' /etc/checkup-secrets/t9a-anthropic-api-key   # root:root 600, about 108 bytes
   ```
3. Content: activation creates the `t9a-tutor` group and `/srv/t9a-tutor/content`
   (`root:t9a-tutor 0750`) but does not start the service until
   `rules/text` exists there (`ConditionPathExists`), so the first start never seeds
   against empty content. Copy the learn-t9a `content/` directory (rules PDFs and
   texts, the teach-era pages, the army list). From a learn-t9a checkout on the Mac:
   ```sh
   rsync -a --delete content/ maurerf.com:/tmp/t9a-content/
   ssh maurerf.com 'sudo rsync -a --delete --chown=root:t9a-tutor --chmod=D750,F640 /tmp/t9a-content/ /srv/t9a-tutor/content/ && rm -rf /tmp/t9a-content'
   ```
4. Progress data (optional, once, before the first start): stop the app on the
   desktop and run `sqlite3 app/.state/t9a.sqlite 'PRAGMA wal_checkpoint(TRUNCATE)'`.
   On the VPS create the state dir (`sudo install -d -o t9a-tutor -g t9a-tutor -m 0700
   /var/lib/t9a-tutor`) and put that file there as `t9a.sqlite`, owner `t9a-tutor`,
   mode 0600, with no `t9a.sqlite-wal`/`-shm` beside it. Without it the app seeds
   itself on first start (imported records and flashcard state, no later progress).
   Then `sudo systemctl start t9a-tutor`.
5. Page images, as the service user:
   `sudo -u t9a-tutor env T9A_CONTENT_DIR=/srv/t9a-tutor/content T9A_STATE_DIR=/var/lib/t9a-tutor t9a-render-pages`
6. Password: the first visitor sets it. Set it promptly through an SSH tunnel
   (`ssh -L 5179:127.0.0.1:5179 maurerf.com`, then `http://127.0.0.1:5179`), ideally
   before DNS points at the VPS. Everything except the login is behind it.

## Checks after activation

`curl -s https://t9a.maurerf.com/api/health` gives `{"ok":true}`;
`curl -s -o /dev/null -w '%{http_code}' https://t9a.maurerf.com/api/topics` gives 401; one rules question in the app returns verified quotes;
`/var/lib/t9a-tutor/tutor-usage.jsonl` gains a line per tutor call; `systemctl status
t9a-tutor` shows the memory peak.

## Backups and state

State is `/var/lib/t9a-tutor` (mode 0700): `t9a.sqlite`, daily backups in `backups/`,
page images in `pages/` (rebuildable), `tutor-usage.jsonl`. Copy the backups off the
VPS; the disk had 29 GiB free on 2026-11-19. Revoke the API key in the Console if the VPS or the
key file may be exposed.
