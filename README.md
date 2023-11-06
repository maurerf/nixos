# nixos
This is my personal NixOS configuration.

### Installation for Desktop PC / Laptop
1. Install NixOS using a live installation medium.
2. `nix-shell -p git`
3. `git clone https://github.com/maurerf/nixos`
4. `sudo cp -r nixos/* /etc/nixos/* && cd /etc/nixos`
5. `sudo nixos-rebuild switch --flake .#gnome-desktop` or `sudo nixos-rebuild switch --flake .#xmonad-desktop`

### Installation of mail server on VPS
1. Install NixOS using a live installation medium.
2. `nix-shell -p git`
3. `git clone https://github.com/maurerf/nixos`
4. `sudo cp -r nixos/* /etc/nixos/* && cd /etc/nixos`
6. `sudo nixos-rebuild switch --flake .#vps`
