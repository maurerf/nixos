# Decisions and limitations

[Knowledge index](README.md)

## Continuing decisions

- Prefer compatible supported stable inputs, sharing nixpkgs; use unstable packages
  only for a demonstrated need. The current pins are declarations in
  [flake.nix](../flake.nix) and [flake.lock](../flake.lock), not a claim of ongoing
  upstream support. Recheck release/migration compatibility for each update.
  [Original rationale](archive/01-checkup/EVIDENCE.md#interview-decisions).
- Keep manual Homebrew ownership separate from Nix apps. Disabled Spotify was
  retained because no approved use or working replacement was established. The
  explicit Dovecot `fileinto` workaround was removed because Dovecot 2.4 enables it
  and the old option failed evaluation. Reassess changes against actual use, not
  cosmetic cleanup. [Source preparation](archive/01-checkup/EVIDENCE.md#release-and-migration-matrix).
- Keep six Mac casks under manual Homebrew: Steam, Claude Desktop, Tor Browser,
  Monero Wallet, Chromium and OpenSCAD (decided 2026-10-14); no Homebrew formulas
  remain. Moving one to Nix needs a refreshed inventory and lock, a native build
  and launch trial and separate approval before Homebrew ownership is removed;
  the [migration record](archive/02-homebrew-migration/README.md#migration-scope-complete-2026-10-14)
  has the per-cask caveats.
- Keep Claude Code and the Codex CLI out of Nix on every host (decided 2026-11-10).
  The user wants new releases, such as new models, as soon as they ship, and the
  nixpkgs `claude-code` package switches its self-updater off. Both are installed
  with their official self-updating installers into `~/.local/bin` (see
  [manual tools](deployment.md#manual-tools)). This reverses the 2026-10-14 move of
  Claude Code from Homebrew to Nix recorded in the
  [Homebrew migration record](archive/02-homebrew-migration/README.md#claude-code-leaves-nix-2026-11-10).
  The Autotools, AutoGen and Doxygen leftovers were dropped at the same time.
  [Decision ticket](https://github.com/maurerf/nixos/issues/29).
- Share Claude Code's status line from Nix while Claude keeps
  `~/.claude/settings.json` (decided 2026-11-14). Claude writes that file at
  runtime, so a Home Manager symlink would make it read-only; activation merges
  only the `statusLine` key instead and leaves a file that is not a JSON object
  untouched. [Ticket](https://github.com/maurerf/nixos/issues/68).
- On `desktop-pc`, `Super+C/V/X/A/Z` (and `Super+Shift+Z`) are Mac-style edit
  keys, so `Ctrl+C` always means interrupt (decided 2026-11-14). xremap runs as
  an fdm user service and asks Niri which app has focus. It turns those keys
  into `Ctrl+…` everywhere except Ghostty, which binds `super+c/v/a` itself.
  fdm is in `input` and `uinput`, so fdm's processes can read every keystroke.
  This was accepted over keyd, whose app mapper needs socket access equivalent
  to root. Niri's center-column and floating toggle moved to `Super+Shift+C/V`,
  and its floating/tiling focus switch to `Super+Ctrl+V`. Nothing changes on
  the Mac. [Research](https://github.com/maurerf/nixos/issues/59),
  [scheme](https://github.com/maurerf/nixos/issues/65).
- Niri binds on `desktop-pc` come from one Nix list that also feeds the hotkey
  overlay (`Super+F1`) and a fuzzel command palette (`Super+Shift+Space`)
  (decided 2026-11-14). Niri matches the key without Shift or AltGr, so on the
  de layout `/`, `=`, `[` and `]` can't be bound. Growing moved to `+` and
  consume-or-expel to `ü`. `Super+Shift+1–9` move the column to a workspace
  instead of Niri's `Super+Ctrl+1–9`. Screenshots use `Super+Shift/Ctrl/Alt+S`
  because the small Apple keyboard has no Print key. The overlay hides
  workspaces 2–9 and the media keys; the palette lists every bind.
  [Bind help](https://github.com/maurerf/nixos/issues/66).
- VS Code on both Workstations is fully declarative: read-only settings and only
  the declared extensions, tuned for reading Markdown, diffs and Git (decided
  2026-11-14). Unlike Claude Code's settings, VS Code needs nothing it writes
  at runtime, so a setting changed in the UI fails and changes go through Nix.
  Its Claude Code extension stays out, as it would pin Claude with the flake;
  Claude runs in the terminal. Diff and Git colours use palette blue/orange
  instead of red vs green. [Ticket](https://github.com/maurerf/nixos/issues/67).
- Keep the Postfix outbound IPv4 override: the old source's Gmail delivery failed
  with `5.7.25` and an IPv6 sender without matching reverse/forward identity.
  Target delivery and SPF/DKIM/DMARC later passed. Changing that route requires
  sender identity and external delivery checks, not just reachability.
  [Candidate rationale](archive/01-checkup/EVIDENCE.md#operator-authorized-candidate-source-and-renewed-validation).
- Preserve original Mac generation 34, accepted Mac generations 35/36, original VPS
  generation 21 and accepted VPS generation 22 with their closures until an explicit
  retirement decision. Do not run GC or delete generations as incidental maintenance.
  Automatic GC evaluated false during the checkup; external cleanup was not proved
  absent. [Retention decision](archive/01-checkup/EVIDENCE.md#legacy-source-investigation-and-maintenance-decision-2026-09-29t090807z091606z).
- `desktop-pc` dual-boot layout (decided 2026-11-10, installed 2026-11-11):
  systemd-boot on the existing Windows ESP, which had only 61.6 MB free, with
  kernels on a 1 GiB XBOOTLDR partition. Windows is detected on the shared ESP, so
  no chain-load setup or second ESP is needed. The NixOS root is btrfs (`@`,
  `@home`, `@nix`) because space freed from `C:` later lands in front of the NixOS
  partitions: growth adds a new partition with `btrfs device add` instead of moving
  partitions. The layout uses zram only, with no hibernation and no Windows
  mounts; suspend stays the only sleep state (confirmed 2026-11-14,
  [suspend ticket](https://github.com/maurerf/nixos/issues/69)). Windows has Fast
  Startup and hibernation off and keeps the RTC in UTC.
  The boot menu defaults to the newest NixOS generation, not `@saved`: NixOS
  rewrites `loader.conf`'s `default` on every switch, so `@saved` would keep
  booting the last-picked entry instead of a new generation.
  [Layout decision](https://github.com/maurerf/nixos/issues/30#issuecomment-6769006073),
  [boot default amendment](https://github.com/maurerf/nixos/issues/30#issuecomment-6772325555).
- The operator's ongoing [snapshot and monthly/quarterly maintenance policy](vps-recovery.md#maintenance-and-preparation)
  remains applicable. Legacy entry points were retired with protected recovery copies;
  use [the canonical recovery procedure](vps-recovery.md#retained-legacy-source-recovery).

## Historical exceptions

These decisions applied to their recorded deployment scope, including explicitly
recorded downstream checkup acceptance. They grant no standing permission for a
future change. Establish fresh readiness or ask for a new scoped decision.

| Recorded exception | Meaning and remaining limitation |
| --- | --- |
| [Mac, 2026-09-26](archive/01-checkup/EVIDENCE.md#operator-revision-and-boundary) | Full backup and independent recovery-console test waived. Operator reported iCloud documents accessible elsewhere and offline Monero recovery material; neither was restore-tested. Some local app settings were accepted as disposable. Critical failure required a separate recovery decision, not automatic rollback. |
| [VPS snapshot, 2026-09-27](archive/01-checkup/EVIDENCE.md#us-05-snapshot-based-recovery-readiness-2026-09-27) | Isolated restore, live-capture consistency, measured duration and post-snapshot reconciliation waived. Possible newer-mail loss explicitly accepted for that checkup; zero loss and recovery within an hour were never proved. |
| [IPv6, 2026-09-28](archive/01-checkup/EVIDENCE.md#layer-1-resolution-and-explicit-ipv6-deferral) | External IPv6 SSH/mail/ACME/AAAA checks deferred; IPv4 acceptance does not establish IPv6 health. |
| [Old-source outbound, 2026-09-28](archive/01-checkup/EVIDENCE.md#operator-authorized-candidate-source-and-renewed-validation) | Failed Gmail baseline explicitly waived for the corrected candidate; target external delivery/authentication still required and later passed. |
| [D-Bus transition, 2026-09-28](archive/01-checkup/EVIDENCE.md#us-06-staged-vps-test-and-d-bus-failure-2026-09-28t194934z195928z) | `test` exited 4 and remains a failed step. A separately approved pinned `boot` and reboot superseded the planned `switch`; postboot checks passed. This was not a successful staged test or permission to reboot after any failure. |

The checkup also left historical installer lineage and original full deployment
source unknown. Mac Chromium cask inventory failed on `command_wrapper`; targeted
inventory and operator-confirmed application launches were accepted instead.
Bootloader declaration equivalence was not established merely from GRUB metadata.
These are unresolved historical limitations, not new defects found by this restructuring.
[Baseline exceptions](archive/01-checkup/EVIDENCE.md#us-01-completion-and-retained-exceptions-2026-09-26).

## Deployment provenance, not today's status

At the final 2026-09-29T09:56Z checkpoint, agent checks and operator transcripts
reported both hosts on runtime source `3f189047eab2f56735f104c822778818662e19c1`,
lock hash `sha256-SXw/9jciRkqk8p/Eb4pttg8U33OpUH8J8GLKzvfEDZ4=`.
The earlier accepted Mac source was `a6478f68937add6ef8026555d2a33ddd323ccb46` with
that same lock. Final Mac generation 36 aligned provenance after a VPS-only source
fix; VPS generation 22 had already been deployed. Native builds and exact output
paths are in the [source/alignment evidence](archive/01-checkup/EVIDENCE.md#source-mac-alignment-and-accepted-host-checks-2026-09-29t090630z091536z).

Later closeout documentation commit `a52e460` and merge `aade9a3` are not runtime
source commits. The [final result](archive/01-checkup/EVIDENCE.md#us-07-ordered-layer-and-final-acceptance-result-2026-09-29t095603z095607z)
records healthy services, accepted Mac workflows and retained recovery generations;
VPS external mail acceptance reuses the unchanged target's 2026-09-28 postboot checks.
The conservative interruption bound was 7 minutes 9 seconds and six controlled
inbound IDs were accounted for. Neither this nor a merged PR proves today's state
or preservation of every post-snapshot message. No hosts were inspected during the
documentation restructuring.
