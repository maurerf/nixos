# T9A tutor web app on the VPS

[Knowledge index](README.md) · [Deployment](deployment.md) · [Fredy](fredy.md)

Self-hosted web app from the private repo `maurerf/learn-t9a` (app PR
maurerf/learn-t9a#15): one Node process on `127.0.0.1:5179`, SQLite state, its
own password login. [`modules/t9a-tutor.nix`](../modules/t9a-tutor.nix) is
imported by `machines/vps.nix` but `services.t9a-tutor.enable` is false, so
nothing runs and the `vps` toplevel is unchanged. Activation is the owner's
decision and needs the [deployment approval](deployment.md#deployment).

> **Memory warning.** Measured on the dev machine, one tutor call through the
> Claude Agent SDK peaks at about 395 MiB (node plus the spawned `claude`
> process; node alone about 125 MiB). With 964 MiB shared with mail and Fredy
> (448 MiB cap) that does not fit safely, and the SDK also needs a logged-in
> Claude Code on the server. Owner decision: a bigger VPS, or an API-key
> backend (the app's tutor interface allows one). Until then the module
> defaults to `tutorBackend = "fake"` and `memoryMax = "256M"`.

## Activation steps

1. DNS: `A`/`AAAA` record `t9a.maurerf.com` to the VPS (as for Fredy).
2. Flake input (changes `flake.lock`; use [/update-flake](../.claude/skills/update-flake/SKILL.md)):
   ```nix
   # inputs.learn-t9a.url = "git+ssh://git@github.com/maurerf/learn-t9a?ref=master";
   # inputs.learn-t9a.inputs.nixpkgs.follows = "nixpkgs";
   ```
   The repo is private, so the evaluating machine needs an SSH key for it.
3. Enable in `machines/vps.nix` (`inputs` is in `specialArgs`):
   ```nix
   # services.t9a-tutor = {
   #   enable = true;
   #   package = inputs.learn-t9a.packages.x86_64-linux.app;
   # };
   ```
   `package` is required when enabled (an assertion fails otherwise).
4. Content: the PDFs and texts must not enter the nix store. As root, check out
   the repo to `/srv/t9a-tutor/content` (module creates it `root:t9a-tutor 0750`),
   containing `text/ sources/ lessons/ assets/ reference/ list/ app/seed/ app/prompts/`.
   Keep files root-owned and not world-readable (`chmod -R o-rwx`).
5. Page images: as the service user, with poppler on PATH, run
   `sudo -u t9a-tutor env T9A_CONTENT_DIR=/srv/t9a-tutor/content T9A_STATE_DIR=/var/lib/t9a-tutor nix shell nixpkgs#poppler-utils -c /srv/t9a-tutor/content/app/scripts/render-pages.sh`.
6. First start: open `https://t9a.maurerf.com` and set the password on the first
   visit (do it promptly: the first visitor sets it; consider an SSH tunnel to
   port 5179 first). Everything except the login is behind that password.

## Backups and state

State is `/var/lib/t9a-tutor` (mode 0700). The app writes daily SQLite backups
to `/var/lib/t9a-tutor/backups`; copy them off the VPS, the disk has about 7 GiB
free. The rendered page images also live under the state dir and can be rebuilt.

## Not yet checked

Not built or run on the VPS. Evaluation results are in the PR description.
