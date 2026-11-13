# iCloud Drive on `desktop-pc`: research findings

Research for [#61](https://github.com/maurerf/nixos/issues/61) (map
[#56](https://github.com/maurerf/nixos/issues/56)). Sources were read on
2026-11-13. No Apple credentials were used, so nothing below was tested against a
live account. Upstream issue states are as of that date.

## Recommendation

**Use iCloud on the web (icloud.com in the browser) for now. Do not add rclone
iCloud to the configuration yet.** Revisit when nixpkgs `nixos-26.05` ships an
rclone that has both the case-insensitivity fix (v1.76.0) and the
"trust token expired right after reconnect" fix (PR #10048, still open). If you
add it after that, use on-demand or timer-driven `rclone copy`/`bisync` with a
**hand-written systemd user unit and an unmanaged config file**, not a FUSE mount
and not Home Manager's `programs.rclone.remotes`.

Why:

1. The pinned rclone (1.75.1) has a known data-loss bug when used through a
   mount: a case-only rename deletes the directory's files on iCloud. It is fixed
   only in 1.76.0, which is not in the pinned nixpkgs or the `nixos-26.05` branch.
2. On 1.75.1, a non-ADP account can fail with "trust token expired" right after a
   successful setup. The fix is still an open PR.
3. Even when it works, the session needs an interactive password + 2FA
   re-authentication every 30 days. An unattended service will break every month.
4. rclone writes refreshed cookies back into `rclone.conf` at runtime. Home
   Manager's rclone module regenerates that file on every login, which would wipe
   the trust token. So the "declarative" route doesn't fit.

## rclone `iclouddrive` backend

### Version in the pin

- `flake.lock` pins nixpkgs `f5c082a40f7571c266e74e80ae2e68aadd8a9fc7`
  (`nixos-26.05`). There, `pkgs/by-name/rc/rclone/package.nix` sets
  `version = "1.75.1"`, built with `enableCmount ? true` (FUSE mount support).
  ([source](https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/pkgs/by-name/rc/rclone/package.nix))
- On 2026-11-13, the `nixos-26.05` branch head has `1.75.2` and `master` has
  `1.76.0`. ([26.05](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/pkgs/by-name/rc/rclone/package.nix),
  [master](https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/rc/rclone/package.nix))
- The backend arrived in rclone v1.69 (`versionIntroduced` in the docs). SRP
  sign-in replaced plaintext sign-in in PR #9209 (merged 2026-04-02). ADP/PCS
  support and Photos came in later (#9234).
  ([docs v1.75.1](https://github.com/rclone/rclone/blob/v1.75.1/docs/content/iclouddrive.md))
- rclone's own backend rating is `tier: Tier 4`, `integration_tests: Flaky`,
  `performance: Low`, `hashes: null`.
  ([iclouddrive.yaml](https://github.com/rclone/rclone/blob/v1.75.1/docs/data/backends/iclouddrive.yaml))

### Authentication, 2FA and session lifetime

- It needs the regular Apple ID password plus 2FA, from a trusted-device prompt
  or SMS. **App-specific passwords are not accepted.**
  ([docs](https://github.com/rclone/rclone/blob/v1.75.1/docs/content/iclouddrive.md#configuration))
- "The trust token is valid for 30 days. After which you will have to
  reauthenticate with `rclone reconnect` or `rclone config`." (same source)
  When it expires, the backend fails with `trust token expired, please reauth`
  ([icloud.go](https://github.com/rclone/rclone/blob/v1.75.1/backend/iclouddrive/icloud.go)).
  Re-authentication is interactive (2FA), so it can't be automated.
- The config holds `apple_id`, `password` (obscured, which is reversible and not
  encryption), `trust_token` and `cookies`. On every client creation the backend
  registers a callback that does `m.Set("cookies", ...)`, so **rclone rewrites
  its config file at runtime**. The file must stay writable and owned by rclone.
  (`newICloudClient` in
  [icloud.go](https://github.com/rclone/rclone/blob/v1.75.1/backend/iclouddrive/icloud.go))
- A YubiKey or security-key 2FA setup may not receive codes:
  [rclone#9734](https://github.com/rclone/rclone/issues/9734) (open).

### Advanced Data Protection

- "Advanced Data Protection is supported." It requires **Settings > Apple
  Account > iCloud > Access iCloud Data on the Web = ON**. With ADP, rclone
  requests PCS cookies after 2FA, and Apple may ask for approval on a trusted
  device. ([docs](https://github.com/rclone/rclone/blob/v1.75.1/docs/content/iclouddrive.md#advanced-data-protection))
- An ADP failure mode is still open: `Missing X-APPLE-WEBAUTH-TOKEN cookie`
  ([rclone#9658](https://github.com/rclone/rclone/issues/9658)). Commenters
  trace it to web access being off, or to pending Apple Terms.
- Turning on web access under ADP widens what Apple's web endpoints can decrypt.
  That's a privacy tradeoff the user has to weigh. The web-only option has the
  same requirement.

### Known open/recent defects relevant to us

| Issue | Status | Impact |
|---|---|---|
| [#10162](https://github.com/rclone/rclone/issues/10162) case-only rename through a mount trashes every file in the directory | Fixed in **v1.76.0** ("Mark the backend as case insensitive"); reproduced on 1.75.1/1.75.2 | **Data loss** with the pinned version, especially via `mount` |
| [#9966](https://github.com/rclone/rclone/issues/9966) fresh non-ADP trust token immediately "expired" | Open; fix PR [#10048](https://github.com/rclone/rclone/pull/10048) open | Setup may not work at all on 1.75.1 |
| [#9730](https://github.com/rclone/rclone/issues/9730) 2FA 409 on non-ADP accounts | Open; PR [#9982](https://github.com/rclone/rclone/pull/9982) open | Setup may fail |
| [#9477](https://github.com/rclone/rclone/issues/9477) subdirectories of folders shared *with* you return HTTP 400 | Open | Shared folders only partly usable |
| [#8176](https://github.com/rclone/rclone/issues/8176) macOS "bundle" directories (e.g. `.pages`, `.key`) | Open | iWork/package files appear as folders |
| [#9798](https://github.com/rclone/rclone/issues/9798) Keynote file rejected: reported vs downloaded size differ | Open | Some iWork files fail to copy |

Changelog: [v1.76.0 / v1.75.2 / v1.75.1](https://github.com/rclone/rclone/blob/v1.76.0/docs/content/changelog.md).

### Mount vs bisync

- **No hashes** (`Hashes()` returns `hash.None`), **modtime precision 1 s**, and
  `SetModTime` returns `ErrorCantSetModTime`. Change detection can only use size
  and modtime. ([iclouddrive.go](https://github.com/rclone/rclone/blob/v1.75.1/backend/iclouddrive/iclouddrive.go))
- **`rclone mount`**: technically possible (cmount is built in). It is the riskier
  shape here, though. The #10162 data loss happens through the VFS, Drive has no
  mount guidance (only Photos has recommended mount flags), and an expired token
  turns the mount into I/O errors under whatever app is using it. It needs
  `--vfs-cache-mode full` (or `writes`) for normal desktop apps.
- **`rclone bisync`**: documented as "an **advanced command**, so use with
  care". It defaults to `--compare size,modtime`, which works without hashes, and
  has safeguards (`--check-access`, `--max-delete` 50% default, `--resilient`).
  It needs a one-time `--resync`. When the token expires it fails loudly, and
  leaves no half-mounted filesystem behind. This is the better fit if rclone is
  used at all.
  ([bisync docs](https://github.com/rclone/rclone/blob/v1.75.1/docs/content/bisync.md))
- **`rclone copy` (one-way, on demand)**: the lowest-risk option for pulling
  specific folders down.

## Alternatives

- **iCloud web (icloud.com in a browser)**: no install, no credentials on disk,
  works with ADP if "Access iCloud Data on the Web" is on. The downsides are
  manual upload/download only and no local file access. Nothing to declare in
  Nix.
- **icloudpd** (nixpkgs pin: `1.32.2`,
  [package.nix](https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/pkgs/by-name/ic/icloudpd/package.nix)):
  **Photos only, not Drive.** It requires web access ON **and ADP OFF**
  ([README v1.32.2](https://github.com/icloud-photos-downloader/icloud_photos_downloader/blob/v1.32.2/README.md#icloud-prerequisites)).
  It doesn't answer this ticket. rclone `service = photos` (read-only) covers the
  same need with ADP.
- No official Apple iCloud client exists for Linux. No other packaged Drive
  client was found in nixpkgs.

## How it would fit Nix (if adopted later)

- **Package**: `home.packages = [ pkgs.rclone ];` in `profiles/home-desktop-pc.nix`
  (Linux-only, not Darwin; the Mac has native iCloud).
- **Config/secrets**: do **not** use `programs.rclone.remotes`. Its
  `rclone-config` user service renders `rclone.conf` from Nix plus `secrets`
  files and `mv -f`s it over the live file at every `default.target` start
  ([HM release-26.05 `modules/programs/rclone.nix`](https://github.com/nix-community/home-manager/blob/a6631107a83ceab5872f298a2ea710859c80c4cb/modules/programs/rclone.nix)).
  That would discard the runtime-written `trust_token`/`cookies`. Instead, keep
  a separate host-local file such as `~/.config/rclone/icloud.conf` (mode 600,
  created interactively with `rclone --config ~/.config/rclone/icloud.conf
  config`) and pass `--config` explicitly. This matches the repo rule that
  runtime credentials are host files, not Nix store contents
  ([architecture](architecture.md)). Nothing secret enters the repo.
- **Service**: a hand-written `systemd.user.services.icloud-bisync` (oneshot) plus a
  `systemd.user.timers` entry (e.g. hourly). Use `bisync --resilient
  --check-access --max-delete 25` against a dedicated subfolder, not the whole
  Drive. Add an `OnFailure=` desktop notification so the monthly 30-day reauth
  (`rclone --config ... config reconnect icloud:`) is noticed.
- **Version gate**: overlay or wait until the nixpkgs pin has rclone ≥ 1.76.0
  plus the #10048 fix. Don't override to a beta build just for this.
