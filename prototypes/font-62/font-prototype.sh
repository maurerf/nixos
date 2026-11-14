#!/usr/bin/env bash
# PROTOTYPE, throwaway: issue #62 "Font prototype: CaskaydiaCove vs Hack Nerd Font".
# Compares fonts live on desktop-pc without touching the Nix config or the
# installed fonts. A private fontconfig file adds both Nerd Fonts from the pinned
# nixpkgs for the launched processes only; nothing persists.
#
# Usage: font-prototype.sh <cask|hack|fira> [bar-px]
#   Opens a specimen Ghostty, a second Waybar at the bottom of the screen and
#   fuzzel, all in the chosen font. Waybar text is bar-px (default 14); fuzzel
#   gets the matching point size (px * 3/4, as fuzzel runs with dpi-aware=no).
#   Close fuzzel with Esc; the script then closes Ghostty and the test bar.
set -euo pipefail

repo=${REPO:-$HOME/Documents/git/nixos}
choice=${1:?usage: $0 <cask|hack|fira> [bar-px]}
bar_px=${2:-14}
fuzzel_pt=$(awk "BEGIN { print $bar_px * 3 / 4 }")

case $choice in
  cask) family="CaskaydiaCove Nerd Font" ;;
  hack) family="Hack Nerd Font" ;;
  fira) family="FiraCode Nerd Font" ;;
  *) echo "unknown font: $choice" >&2; exit 2 ;;
esac

work=$(mktemp -d "${TMPDIR:-/tmp}/font-prototype.XXXXXX")
trap 'kill $(jobs -p) 2>/dev/null || true; rm -rf "$work"' EXIT

mapfile -t fontdirs < <(nix build --no-link --print-out-paths --inputs-from "$repo" \
  nixpkgs#nerd-fonts.caskaydia-cove nixpkgs#nerd-fonts.hack)

{
  echo '<?xml version="1.0"?><!DOCTYPE fontconfig SYSTEM "fonts.dtd"><fontconfig>'
  echo '<include>/etc/fonts/fonts.conf</include>'
  for d in "${fontdirs[@]}"; do echo "<dir>$d/share/fonts</dir>"; done
  echo "<cachedir>$work/cache</cachedir></fontconfig>"
} > "$work/fonts.conf"
export FONTCONFIG_FILE=$work/fonts.conf
fc-match "$family" | sed 's/^/fontconfig match: /'

cat > "$work/specimen.txt" <<'EOF'
  Ambiguity   0O o 1lI| rn m  `'"  ,.;:  {}[]()  <>  ~-_=
  Operators   => -> != == === <= >= && || :: // /* */ |> <-
  Prose       The quick brown fox jumps over the lazy dog. 0123456789
  Nix         { pkgs, ... }: { home.packages = with pkgs; [ ghostty ]; }
  Shell       $ git log --oneline main..HEAD | grep -v 'fixup!' && echo ok
  Diff        - font-family = "FiraCode Nerd Font";
              + font-family = "Hack Nerd Font";
  Markdown    ## Destination  **bold**  _italic_  `code`  [link](url)
  Waybar      vol ▮▮▮▮▯▯   offline   Sat 14 Nov 11:42
EOF
printf '  Nerd icons                        \n' >> "$work/specimen.txt"

# Second bar at the bottom: the real config with this font and size.
sed -e 's/"position": "top"/"position": "bottom"/' -e '/"height": 26,/d' \
  "$HOME/.config/waybar/config" > "$work/bar.json"
sed -e "s/font-family: [^;]*;/font-family: \"$family\";/" \
    -e "s/font-size: [^;]*;/font-size: ${bar_px}px;/" \
    "$HOME/.config/waybar/style.css" > "$work/bar.css"
waybar -c "$work/bar.json" -s "$work/bar.css" >/dev/null 2>&1 &

ghostty --gtk-single-instance=false --title="font prototype: $family" \
  --font-family= --font-family="$family" \
  -e sh -c "echo; echo '  $family  (Ghostty default size)'; echo; cat '$work/specimen.txt'; echo; echo '  Esc in fuzzel closes everything'; exec sleep infinity" &

sleep 1
echo "Waybar ${bar_px}px, fuzzel ${fuzzel_pt}pt: $family"
fuzzel --font="$family:size=$fuzzel_pt" --prompt="$choice ${bar_px}px › " || true
