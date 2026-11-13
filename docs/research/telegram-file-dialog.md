# Telegram's Qt file dialog under Niri (research)

Research for [issue #58](https://github.com/maurerf/nixos/issues/58), part of
map [#56](https://github.com/maurerf/nixos/issues/56). Sources read and the live
system inspected (read-only) on 2026-11-13. Nothing was changed, rebuilt or
switched. The fix below has not been tested end to end.

Target: `desktop-pc`, NixOS 26.05 (nixpkgs `f5c082a`), Niri session started by
`niri-session`, Telegram Desktop 7.1.5 (Qt 6.11.2), KeePassXC 2.7.12 (Qt 5.15.19).

## Answer in short

The portals are fine. Telegram never asks them. Qt picks its *platform theme*
from `XDG_CURRENT_DESKTOP`, and it only knows KDE and a fixed list of GTK
desktops. For `niri` it falls back to the generic Unix theme, which has no
native file dialog. Every `QFileDialog::get*()` call then draws Qt's own
widget dialog in the light Fusion palette. Qt only loads its
`xdgdesktopportal` theme on its own inside Flatpak or Snap. Elsewhere it needs
`QT_QPA_PLATFORMTHEME`.

Smallest fix, in `profiles/home-desktop-pc.nix` next to the existing GTK
dark-mode settings:

```nix
# Qt does not recognise XDG_CURRENT_DESKTOP=niri and falls back to its own
# widget file dialog; route QFileDialog through the portal (gnome backend).
home.sessionVariables.QT_QPA_PLATFORMTHEME = "xdgdesktopportal";
```

The variable takes effect after logging out and back in, and Telegram and
KeePassXC must then be restarted. It reroutes only the file dialog, because
the portal theme passes palette, fonts and icons through to the same generic
base theme Qt uses today.

## Why Qt falls back

1. **Theme candidate list.** `init_platform()` (called from `QGuiApplicationPrivate::createPlatformIntegration`)
   builds the list in this order: `QT_QPA_PLATFORMTHEME`; then `xdgdesktopportal`,
   but only if `/.flatpak-info` exists or `SNAP` is set; then the platform
   integration's `themeNames()`. The first theme that loads wins. If none
   loads, Qt uses the null `QPlatformTheme`.
   ([qtbase v6.11.2 `src/gui/kernel/qguiapplication.cpp`](https://github.com/qt/qtbase/blob/v6.11.2/src/gui/kernel/qguiapplication.cpp),
   `checkNeedPortalSupport()` and the "Create the platform theme" block.)
2. **No Niri entry.** `QGenericUnixTheme::themeNames()` maps `KDE` to `kde`.
   It maps `GNOME`, `X-CINNAMON`, `PANTHEON`, `UNITY`, `MATE`, `XFCE` and
   `LXDE` to `gtk3`, then `gnome`. Any other desktop name is just lower-cased,
   then `generic` is appended. On this host that gives `niri`, which has no
   plugin, and then `generic`.
   ([qtbase v6.11.2 `src/gui/platform/unix/qgenericunixtheme.cpp`](https://github.com/qt/qtbase/blob/v6.11.2/src/gui/platform/unix/qgenericunixtheme.cpp).)
   Qt 5.15 uses the same logic, so KeePassXC is affected too
   ([qtbase v5.15.2 `qgenericunixthemes.cpp`](https://github.com/qt/qtbase/blob/v5.15.2/src/platformsupport/themes/genericunix/qgenericunixthemes.cpp),
   [`qguiapplication.cpp`](https://github.com/qt/qtbase/blob/v5.15.2/src/gui/kernel/qguiapplication.cpp)).
3. **The portal theme forces native file dialogs.** `QXdgDesktopPortalTheme`
   returns `true` from `usePlatformNativeDialog(FileDialog)`. When the
   `org.freedesktop.portal.FileChooser` version can be read, it creates a
   `QXdgDesktopPortalFileDialog`. Palette, fonts, menus and the tray are all
   delegated to a base theme taken from the same `themeNames()`, so on Niri
   that is still `generic`. The theme also reads `org.freedesktop.appearance`
   `color-scheme` from the portal Settings interface.
   ([qtbase v6.11.2 `src/plugins/platformthemes/xdgdesktopportal/qxdgdesktopportaltheme.cpp`](https://github.com/qt/qtbase/blob/v6.11.2/src/plugins/platformthemes/xdgdesktopportal/qxdgdesktopportaltheme.cpp).)

## Telegram specifics

- On Linux, Telegram's `Platform::FileDialog::Get` simply forwards to
  `::FileDialog::internal::GetDefault`
  ([tdesktop v7.1.5 `platform/linux/file_utilities_linux.h`](https://github.com/telegramdesktop/tdesktop/blob/v7.1.5/Telegram/SourceFiles/platform/linux/file_utilities_linux.h)).
  That function calls the static `QFileDialog::getOpenFileName(s)`,
  `getSaveFileName` and `getExistingDirectory` without
  `DontUseNativeDialog`
  ([`core/file_utilities.cpp`](https://github.com/telegramdesktop/tdesktop/blob/v7.1.5/Telegram/SourceFiles/core/file_utilities.cpp)).
  Telegram has no file-chooser portal code or toggle of its own. The dialog
  you get depends entirely on the Qt platform theme.
- The 7.1.5 binary contains none of the strings `QT_QPA_PLATFORMTHEME`,
  `xdgdesktopportal`, `GTK_USE_PORTAL` or any `TDESKTOP_*` dialog variable.
  The only `TDESKTOP_` string is `TDESKTOP_SHELL_TOKEN_PLACEHOLDER` (`grep -a`
  over `.Telegram-wrapped`). The nixpkgs `makeCWrapper` sets only search paths
  (`LD_LIBRARY_PATH`, `XDG_DATA_DIRS`, `QT_PLUGIN_PATH`, …), not a theme. So
  nixpkgs does not make Telegram use portals by default, and no Telegram
  variable controls it.
- `GTK_USE_PORTAL` has no effect here. It applies only to GTK's own
  `GtkFileChooserNative`, and Telegram draws no GTK dialog.

## Live system observations (2026-11-13)

- Portal backends in `/run/current-system/sw/share/xdg-desktop-portal/portals`:
  `gnome.portal`, `gtk.portal`, `gnome-keyring.portal`. These come from
  `programs.niri.enable` (`machines/desktop-pc.nix`).
- `niri-portals.conf` sets `default=gnome;gtk;`, with only Access/Notification
  sent to `gtk` and Secret sent to `gnome-keyring`. FileChooser therefore
  resolves to **xdg-desktop-portal-gnome 50.0**. No override exists in
  `~/.config/xdg-desktop-portal`.
- `xdg-desktop-portal` 1.20.4, `-gnome` and `-gtk` user services are all
  active. `busctl --user get-property … org.freedesktop.portal.FileChooser version`
  returns `4`, which supports directory selection (`getExistingDirectory`).
- Portal Settings `org.freedesktop.appearance color-scheme` returns `1`
  (prefer-dark). That value comes from the Home Manager `dconf` setting in
  `profiles/home-desktop-pc.nix`.
- The running Telegram process (`telegram-desktop-7.1.5`) has
  `XDG_CURRENT_DESKTOP=niri` and no `QT_QPA_PLATFORMTHEME`. Its
  `QT_PLUGIN_PATH` includes `qtbase-6.11.2/lib/qt-6/plugins`, whose
  `platformthemes/` holds `libqxdgdesktopportal.so` and `libqgtk3.so`. The
  plugin is already reachable, and only the selection is missing. The
  KeePassXC wrapper points at `qtbase-5.15.19-bin` plugins, which also ship
  `libqxdgdesktopportal.so`.
- Both kinds of session variable reach Telegram. Its environment contains
  `NIXOS_OZONE_WL` (NixOS `environment.sessionVariables`) and
  `GTK2_RC_FILES` (Home Manager `home.sessionVariables`).

## KeePassXC

KeePassXC 2.7.12 opens files through static `QFileDialog::get*()` calls with
caller-supplied options
([`src/gui/FileDialog.cpp` at 2.7.12](https://github.com/keepassxreboot/keepassxc/blob/2.7.12/src/gui/FileDialog.cpp)).
It is built on Qt 5.15, whose theme selection is the same (see above), so it
shows the same fallback and gets the same fix. This is inferred from source
and not observed live: the process is non-dumpable, so its environment could
not be read.

## Options considered

| Option | Effect | Verdict |
| --- | --- | --- |
| `home.sessionVariables.QT_QPA_PLATFORMTHEME = "xdgdesktopportal"` | Qt file dialogs go to the portal (xdp-gnome, dark via `color-scheme`). Everything else stays on the generic base theme. | **Recommended.** One line, host-only, next to the GTK dark settings. |
| Same variable via `environment.sessionVariables` in `machines/desktop-pc.nix` | Same effect, system-wide. | Fine too. The home profile keeps theming in one place. |
| NixOS `qt.platformTheme` | The enum allows only `gnome`, `gtk2`, `kde`, `lxqt` and `qt5ct`. `xdgdesktopportal` is rejected. ([nixpkgs `nixos/modules/config/qt.nix` @ f5c082a](https://github.com/NixOS/nixpkgs/blob/f5c082a40f7571c266e74e80ae2e68aadd8a9fc7/nixos/modules/config/qt.nix)) | Not usable. |
| Home Manager `qt.enable` + `qt.platformTheme.name = "xdgdesktopportal"` | Accepted, because the name is a free `str` and becomes `QT_QPA_PLATFORMTHEME`. It also sets `QT_PLUGIN_PATH`/`QML2_IMPORT_PATH` to profile paths. ([home-manager `modules/misc/qt.nix` @ a663110](https://github.com/nix-community/home-manager/blob/a6631107a83ceab5872f298a2ea710859c80c4cb/modules/misc/qt.nix)) | Works, but changes more than needed. |
| `QT_QPA_PLATFORMTHEME = "gtk3"` | Qt uses its GTK3 theme: an in-process GTK3 file chooser plus a GTK-derived palette and fonts for Qt widgets. | Larger change. It bypasses the portal and alters Qt widget look. |
| Change portal config (`xdg.portal.config`) | FileChooser already resolves to xdp-gnome. | Not the cause, so no change needed. |

## Things to check after applying

- Telegram: Settings → Advanced → Download path → choose folder, and a
  "Save as". Expect the dark xdg-desktop-portal-gnome chooser. Check whether
  the dark appearance holds. The portal reports prefer-dark, and xdp-gnome is
  a libadwaita app, but this was not observed.
- KeePassXC: Open database. Expect the same chooser.
- Side effect to watch: under the portal theme, Qt reports
  `Qt::ColorScheme::Dark` from the portal. Apps that follow the system scheme,
  such as Telegram's "match system theme" night mode or Qt 6 Fusion widgets,
  may switch to dark. That is likely welcome but unverified.
