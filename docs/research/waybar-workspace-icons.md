# Research: window icons on Waybar's `niri/workspaces`

Ticket: #60 (map #56). Researched 2026-11-13 against the repo at `56dae95`
(flake.lock nixpkgs `f5c082a4`, branch `nixos-26.05`). Read-only; nothing was
built or switched on `desktop-pc`.

## Question

Can the `niri/workspaces` module in the pinned nixpkgs show each workspace's
open windows as app icons next to its number (`1 󰈹 `)? If not, compare
alternatives and recommend one.

## Answer

**Not with the pinned Waybar (0.15.0). Yes with Waybar 0.16.0**, released
2026-11-05, which adds `{windows}` + `window-rewrite` (Nerd Font glyphs/text)
and a `workspace-taskbar` mode (icon-theme images) to `niri/workspaces`.
0.16.0 is in `nixos-unstable` but not in `nixos-26.05`.

**Recommendation:** use the native 0.16.0 `{windows}` / `window-rewrite`
feature with Nerd Font glyphs (`format = "{index} {windows}"`), taking the
`waybar` package from a pinned `nixos-unstable` input until the flake moves to
NixOS 26.11 (planned end of November 2026), then drop the extra input.

## Findings

### 1. Pinned versions

| Item | Value | Source |
|---|---|---|
| nixpkgs | `nixos-26.05`, rev `f5c082a40f7571c266e74e80ae2e68aadd8a9fc7` | `flake.nix`, `flake.lock` |
| `pkgs.waybar.version` | `0.15.0` | `nix eval .#nixosConfigurations.desktop-pc.pkgs.waybar.version` |
| `pkgs.niri.version` | `26.04` | same, `pkgs.niri.version` |
| nixpkgs `waybar` on `nixos-26.05` | `0.15.0` | `pkgs/by-name/wa/waybar/package.nix@nixos-26.05` |
| nixpkgs `waybar` on `nixos-unstable` | `0.16.0` (NixOS/nixpkgs#583754, merged 2026-11-07, base `master`, no backport label) | `package.nix@nixos-unstable`, PR metadata |

No backport PR of 0.16.0 to `release-26.05` was found (GitHub search
`repo:NixOS/nixpkgs waybar base:release-26.05`).

### 2. Waybar 0.15.0 `niri/workspaces` (what is pinned)

From the pinned source (`man/waybar-niri-workspaces.5.scd`,
`src/modules/niri/workspaces.cpp`):

- Format replacements: `{value}`, `{name}`, `{icon}`, `{index}`, `{output}`
  only. The `fmt::format` call in `workspaces.cpp` passes exactly these.
- `format-icons` selects **one** icon per workspace by name/index/state
  (`urgent`, `active`, `focused`, `empty`, `default`). It knows nothing about
  the windows on the workspace.
- No `window-rewrite`, no `{windows}` (those exist only in the Sway and
  Hyprland modules in 0.15.0).

So per-window app icons are **not possible** natively in the pinned version.

### 3. Waybar 0.16.0 `niri/workspaces` (upstream, released 2026-11-05)

Added by Alexays/Waybar commits `9e10a9a` "feat(niri/workspaces): add window
icons via window-rewrite" and `9cd09c2` "feat(niri): add workspace-taskbar
support" (both 2026-07-03, in tag `0.16.0`). From
`man/waybar-niri-workspaces.5.scd@0.16.0` and
`src/modules/niri/workspaces.cpp` / `workspace.cpp@0.16.0`:

- **`{windows}` + `window-rewrite`** (text): keys are regexes in the form
  `app_id<regex>` and/or `title<regex>`; values are strings (Nerd Font glyphs,
  Pango markup, `{app_id}`/`{title}` placeholders). Lookup order in
  `Workspaces::getRewrite`: `app_id<…> title<…>`, then `app_id<…>`, then
  `title<…>`, then `window-rewrite-default` (default `"?"`). Windows are joined
  with `format-window-separator` (default `" "`).
- **`workspace-taskbar`** (images): `{ enable = true; icon-size = 16; }`
  renders real icons inside each workspace button. `Workspace::loadIcon`
  resolves `<app_id>.desktop` via `Gio::DesktopAppInfo` and looks its icon up
  in the GTK icon theme, falling back to an icon named after the app_id. Master
  (`c8f034d`, 2026-11-08, after 0.16.0) adds a vertical-orientation option.
- Other new options: `display-condition`, `hide-empty`, `ignore-workspaces`,
  `{total}`.

Example from the 0.16.0 man page:

```jsonc
"niri/workspaces": {
  "format": "{icon} {windows}",
  "window-rewrite-default": "",
  "window-rewrite": { "app_id<firefox>": "", "app_id<foot>": "" }
}
```

### 4. Icon mapping: Nerd Font glyphs vs icon theme

| | `window-rewrite` (glyphs) | `workspace-taskbar` (icon theme) |
|---|---|---|
| Mapping | Hand-written app_id regex → glyph table in Nix | Automatic from `.desktop` file / icon theme |
| Unknown apps | `window-rewrite-default` glyph | Theme lookup by app_id; may be blank |
| Look | Monochrome, inherits CSS colour (palette-friendly, matches the text bar decision in #56) | Full-colour app icons |
| Deps | A Nerd Font in the bar font (repo installs FiraCode / DroidSansMono Nerd Fonts; #56 picks one) | An icon theme with the apps' icons |
| Maintenance | Add a line per new app | None |

The map's standing decision is a text-styled bar with "number + app icons"
and a Nerd Font chosen for icons, so glyphs fit best. Current apps whose
app_ids need rules: Firefox (`firefox`), Ghostty (`com.mitchellh.ghostty`),
VS Code (`code`), Thunderbird, KeePassXC, Telegram; verify exact ids with
`niri msg -j windows` on the host before writing the table.

### 5. Alternatives

**a. niri-taskbar (Waybar CFFI module)** — <https://github.com/LawnGnome/niri-taskbar>

- A separate taskbar module (`cffi/niri-taskbar`) listing all windows ordered
  by workspace; it does **not** put icons inside the workspace number buttons
  (README).
- Built against a specific niri: crate `0.4.0+niri.25.11`, `niri-ipc =
  ">=25.11.0, <25.12.0"` (Cargo.toml). The host runs niri 26.04; no matching
  release found (last push 2025-12-04).
- **Not in nixpkgs** (`pkgs/by-name/ni/niri-taskbar` absent on
  `nixos-unstable`; only `niri`, `niri-sidebar`, `nirimod`, `nirimon`,
  `niriswitcher`, `nirius` exist). Would need our own `rustPlatform` package +
  `module_path`.
- Verdict: wrong shape (separate taskbar), version-locked to an older niri,
  self-packaged. Rejected.

**b. Custom script module on `niri msg -j event-stream`**

- Script keeps state from `WorkspacesChanged` / `WindowsChanged` /
  `WindowOpenedOrChanged` / `WindowClosed` / `WorkspaceActivated` events and
  prints Waybar JSON (`return-type = "json"`).
- Works on 0.15.0 today, but a custom module is a single label: per-workspace
  click-to-focus, `active`/`urgent` button classes and the existing
  `#workspaces button` CSS would be lost or need one module per index.
- Cost: a script (jq/Python) to write, test and maintain against niri IPC
  changes, re-implementing what 0.16.0 now does natively. Rejected unless
  upgrading Waybar is ruled out.

**c. Override `waybar` 0.15.0 → 0.16.0 with `overrideAttrs` on 26.05**

- The nixpkgs bump (#583754) also changes the bundled libcava to a pinned git
  rev and adds new inputs (`modemmanager`) and flags (`mangoSupport`,
  `umbrielSupport`, `wwanSupport`), so a bare `src` swap is not enough; it
  would also be a local compile with no binary cache. Not worth it for a
  weeks-long gap.

**d. Waybar from a pinned `nixos-unstable` input (recommended bridge)**

- Add e.g. `nixpkgs-unstable` input and set
  `programs.waybar.package = unstable.waybar;` in
  `profiles/home-desktop-pc.nix` only.
- Fully cached: `nix build --dry-run` of `waybar` at nixos-unstable
  `d4f25a3e` fetches 321 paths (350 MiB download, ~1 GiB unpacked), no builds.
  This duplicates GTK/glib etc. from a second nixpkgs.
- Adds a second nixpkgs to `flake.lock` that `update-flake` must track; remove
  it when the flake moves to 26.11.

**e. Wait for NixOS 26.11**

- NixOS/nixpkgs#567567 plans the 26.11 release for end of November 2026; it
  will ship Waybar ≥ 0.16.0. Zero extra cost, but the feature waits for the
  release-upgrade migration of all hosts.

## Cost summary

| Option | Shape fits ("1 󰈹 ") | Nix cost | Maintenance |
|---|---|---|---|
| 0.16.0 native via unstable input (d) | Yes | 1 input, ~1 GiB closure on desktop-pc | Glyph table; drop input at 26.11 |
| Wait for 26.11 (e) | Yes | None | Glyph table |
| `overrideAttrs` 0.16.0 (c) | Yes | Local build, fragile override | High |
| Custom event-stream script (b) | Partly (loses buttons) | Small | Script vs niri IPC |
| niri-taskbar CFFI (a) | No | Own Rust package | Niri-version locked |

## Open points for the implementing ticket (#63)

- Decide bridge (d) vs waiting (e); if 26.11 lands before #63 is picked up,
  skip (d).
- Confirm app_ids on the host with `niri msg -j windows`.
- Check the bar font choice from #56 provides the chosen glyphs.
